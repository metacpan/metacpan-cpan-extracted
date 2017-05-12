############################################################################
############################################################################
##                                                                        ##
##    Copyright 2004 Stephen Patterson (steve@patter.mine.nu  )           ##
##                                                                        ##
##    A cross platform perl printer interface                             ##
##    This code is made available under the perl artistic licence         ##
##                                                                        ##
##    Documentation is at the end (search for __END__) or process with    ##
##    pod2man/pod2text/pod2html                                           ##
##                                                                        ##
############################################################################
############################################################################

# Win32 Routines

############################################################################
sub list_printers {
    # list available printers
    my $self = shift();
    my %printers;

    # look at registry to get printer names for local machine
    my $Register = 'SYSTEM\CurrentControlSet\Control\Print\Printers';
    my ($hkey, @key_list, @names, @ports);
    my $HKEY_LOCAL_MACHINE = $main::HKEY_LOCAL_MACHINE;
    $HKEY_LOCAL_MACHINE->Open($Register, $hkey) or 
      Carp::croak "Can't open registry key HKEY_LOCAL_MACHINE\\$Register: $!";
    $hkey->GetKeys(\@key_list);
    foreach my $key (@key_list) {
	my $path = $Register . '\\' . $key;
	my ($pkey, %values, $printers);
	$HKEY_LOCAL_MACHINE->Open($path, $pkey) or 
	  Carp::croak "Can't open registry key  HKEY_LOCAL_MACHINE\\$path: $!";
	$pkey->GetValues(\%values);
	push @ports, $values{Port}[2];
	push @names, $values{Name}[2];
    }
    $printers{name} = [ @names ];
    $printers{port} = [ @ports ];
    return %printers;
}
######################################################################
sub use_default {
    # select the default printer
    my $self = shift;
    my ($hkey, %values);

    # default name is the human readable printer name (not port)
    # look in the registry to find it
    if ($self->{winver} eq ('Win95' or 'Win98' or 'WinNT4')) {
	# the old routines, win95/nt4 tested
	my $register = 'Config\0001\SYSTEM\CurrentControlSet\Control\Print\Printers';
	my $HKLM = $main::HKEY_LOCAL_MACHINE;
	$HKLM->Open($register, $hkey) or 
	  Carp::croak "Can't open registry key " . $register
	      . "in use_default(): $EXTENDED_OS_ERROR\n";
	$hkey->GetValues(\%values);
	my $default = $values{Default}[2];
	# $default holds the long printer name, get the port
	$register = 'SYSTEM\CurrentControlSet\Control\Print\Printers\\';
	my $path = $register . $default;
	$HKLM->Open($path, $HKEY) or
	  Carp::croak "Can't open registry key $path in use_default() "
	      . $EXTENDED_OS_ERROR;
	$hkey->GetValues(\%values);
	$self->{'printer'}{$OSNAME} = $values{Port}[2];
    } elsif ($self->{winver} =~ /2000/) {
	# pull it from a different registry path
	my $register = 'Software\Microsoft\Windows NT\CurrentVersion\Windows';
	my $HKCU = $main::HKEY_CURRENT_USER;
	$HKCU->Open($register, $hkey) or
	  Carp::croak "Can't open registry key " . $register
	      . "in use_default(): $EXTENDED_OS_ERROR\n";
	$hkey->GetValues(\%values);
	my $default = $values{Device}[2];
	# $default holds the long printer name, get the port
	$register = 'SYSTEM\CurrentControlSet\Control\Print\Printers\\';
	my $path = $register . $default;
	my $HKLM = $main::HKEY_LOCAL_MACHINE;
	$HKLM->Open($path, $HKEY) or
	  Carp::croak "Can't open registry key $path in use_default() "
	      . $EXTENDED_OS_ERROR;
	$hkey->GetValues(\%values);
	$self->{'printer'}{$OSNAME} = $values{Port}[2];
    } elsif ($self->{winver} =~ /XP/) {
	# bugger. nothing appropriate in registry for windows XP
	# pick 1st available printer
	my %printers = $self->list_printers;
	$self->{printer}{$OSNAME} = $printers{port}[0];
    }
}
######################################################################
sub list_jobs {
    # list the current print queue
    my $self = shift;
    # return an empty queue (for compatibility)
    # Carp::croak 'list_jobs  hasn\'t yet been written for windows. Share and enjoy';
    my ($pHandle, @jobs, $start);
    $start = 0;

    $OpenPrinter = new Win32::API('Winspool.drv',
			      'OpenPrinter',
			      [P, P, P],
			      I);
    $ClosePrinter = new Win32::API('Winspool.drv',
			       'ClosePrinter',
			       [P],
			       I) || die $!;
    $GetLastError = new Win32::API('kernel32.dll',
			       'GetLastError',
			       I) || die $!;

    # human readable printer name
    my $pName = $self->{'printer'}{'MSWin32'};

    $pHandle = " " x 128; # init a char buffer
    $OpenPrinter->Call($pName, $pHandle, NULL) or Carp::croak 
      "couldn't open printer handle for list_jobs $GetLastError->Call";
    $pHandle =~ s/\0.*$//;

    GetJobs($pHandle, @jobs, $start) || die "Couldn't call GetJobs via xs\n";
    print @jobs;
}
######################################################################

######################################################################
##                                                                  ##
##    Extra windows drivers for specific data types                 ##
##                                                                  ##
######################################################################

######################################################################
sub MS_word {
    # understood by MS Word
    require Win32::OLE;
#    require Win32::OLE::Const qq(Microsoft Word);
    my ($self, $spoolfile) = @_;
    my $Word = Win32::OLE->new('Word.Application', 'Quit');
    $Word->ActivePrinter($self->{'printer'}{$OSNAME});
    $Word->Documents->Open($spoolfile) or Carp::croak
      ("unable to open document", Win32::OLE->LastError());
    $Word->ActiveDocument->PrintOut({
				     Background => 0,
				     Append => 0,
				     Range => wdPrintAllDocument,
				     Item => wdPrintDocumentContent,
				     Copies => 1,
				     PageType => wdPrintAllPages});
    unlink $spoolfile;
}
######################################################################
sub MS_excel {
    # understood by MS Excel
    require Win32::OLE;
#    require Win32::OLE::Const 'Microsoft Excel';
    my ($self, $xlfile) = @_;
    my $xl_app = Win32::OLE->new('Excel.Application', 'Quit') or Carp::croak
      ("Cannot start excel", Win32::OLE->LastError);
    my $workbook = $xl_app->Workbooks->Open($xlfile) or Carp::croak
      ("Can't open file", Win32::OLE->LastError);
    my $worksheet = $workbook->Worksheets(1);
    $worksheet->PrintOut;
    $xl_app->Quit;
}
######################################################################
sub MS_ie {
    # internet explorer
    require Win32::OLE;
    my ($self, $spoolfile) = shift();
    my $IE = Win32::OLE->new('InternetExplorer.Application', 'Quit') or
      Carp::croak("Cannot start Internet Explorer", Win32::OLE->LastError);
    $IE->navigate($spoolfile);
    # or Window.Print
    # IE can't set printer or orientation
    sleep 1 while ($explorer->{ReadyState} < 4);
    $explorer ->{Visible} = 1;
#    sleep(5);
    $IE->ExecWB(6, 1); # print with prompt
    $IE->Quit();
}
######################################################################
sub print {
    # new style printing - just use stuff from wasx
    my ($self, $data) = @_;
    my $self = shift;
    my $data = join('', @_);
    # paper orientation
    my $orient;
    if ($self->{orientation} =~ /landscape/) {
	$orient = 2;
    } else {
	$orient = 1;
    }

    print "printing $data to $self->{printer}{$OSNAME}, orientation $orient\n";

    my $printer = new Win32::Printer( papersize   => 9, # USE a4
				      dialog      => 0,
				      orientation => $orient,
				      printer     => $self->{printer}{$OSNAME},
				      unit        => 'mm');
    my $font = $printer->Font('Arial', 10);
    $printer->Font($font);
    $printer->Write($data, 10, 10);
    $printer->Close;
}
######################################################################
sub print_orig {
    # print- old style - deprecated to use Win32::Printer from wasx,
    # Printer.pm versions 0.98 onwards
    my $self = shift;
    my $data = join("", @_);
    unless ($self->{print_command}->{$OSNAME}) {
	# default pipish method
	my $printer = $self->{'printer'}{$OSNAME};

	# Windows NT variations
	if ($self->{winver} =~ m/WinNT|Win2000/ ) {
	    open SPOOL, ">>$printer" or
	      Carp::croak "Can't open print spool " . $printer . ": $!" ;
	    print SPOOL $data or
	      Carp::croak "Can't write to print spool $self->{'printer'}: $!";
	    close SPOOL;
	} elsif ($self->{winver} =~ m/WinXP/) {
	    open SPOOL, ">>$printer" or
	      Carp::croak "Can't open print spool " . $printer . ": $!" ;
	    print SPOOL $data or
	      Carp::croak "Can't write to print spool $self->{'printer'}: $!";
	    close SPOOL;
	}

	# any other windows version
	# for win95, may work with ME
	else {
	    my $spoolfile = get_unique_spool();
	    open SPOOL, ">" . $spoolfile;
	    print SPOOL $data;
	    close SPOOL;
	    system("copy /B $spoolfile $self->{printer}{$OSNAME}");
	    unlink $spoolfile;
	}

    } else {
	# custom print command
	if ($self->{print_command}->{$OSNAME}->{type} eq 'command') {
	    # non-pipe accepting command - use a spoolfile
	    my $cmd = $self->{print_command}->{$OSNAME}->{command};
	    my @specials = qw(MS_word MS_excel MS_ie);
	    my $spoolfile = get_unique_spool();
	    $cmd =~ s/FILE/$spoolfile/;
	    open SPOOL, ">" . $spoolfile;
	    print SPOOL $data;
	    close SPOOL;

	    if (grep /$cmd/, @specials) {
		# run my new Win32^::OLE methods
		if ($cmd eq 'MS_word') {
		    $self->MS_word($spoolfile);
		} elsif ($cmd eq 'MS_excel') {
		    $self->MS_excel($spoolfile);
		} elsif ($cmd eq 'MS_ie') {
		    $self->MS_ie($spoolfile);
		}
	    } else {
		system($cmd) or die $OS_ERROR;
		unlink $spoolfile;
	    }
	} else {
	    # pipe accepting command
	    # can't use this - windows perl doesn't support pipes.
	}
    }
}
######################################################################
1;

