package SwitchMac;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


#################### subroutine header begin ####################

=head2 setMac

 Usage     : setMac($macaddress,$adapter_name);
 Purpose   : Set a new mac address to a specific adapter
 Argument  : $macaddress, $adapter_name
 Comment   : This function will set a new address specified
           : to a specific mac address

=cut

#################### subroutine header end ####################

sub setMac
{
  my($macaddress,$adapter_name)=@_;
  system("sudo ifconfig $adapter_name down");
 
  system("sudo ifconfig $adapter_name hw ether $macaddress");
  
  system("sudo ifconfig $adapter_name up");
}

#################### subroutine header begin ####################

=head2 setMac

 Usage     : setMacList($listMAC_file_name,$adapter_name,
           :             $frequency,$setTime);
 Purpose   : Set a new mac address based on the list to a 
           :  specific adapter with time and frequency 
           :  switch
 Argument  : $macaddress, $adapter_name, $frequency, $setTime
 Comment   : This function will set a new address specified on
           : the list to a specific mac address with frequency 
           : and time change.

Example    : setMacList(listMac.txt,wlan0,10,60)
           :
           : Here the mac will changes 10 times after 60 seconds

=cut

#################### subroutine header end ####################

sub setMacList
{
  my($listMAC_file_name,$adapter_name,$frequency,$setTime)=@_;
  my@list;
  unless(open(FILE,"<$list_file_name")){
    die "Erro ao abrir arquivo para leitura!";
  }

  while(<FILE>){
    $_ =~ s/\n//g;
    push(@list,$_);
  }

  srand(time^$$);
  my$MACFake = $list[rand($#list)]; 

  system("sudo ifconfig $adapter_name down"); 

  system("sudo ifconfig $adapter_name hw ether $MACFake"); 
  print "New Faked MAC: $MACFake\n";  

  print "\n"; 
  system("sudo ifconfig $adapter_name up");
  
  for(my$x=0; $x<= ($frequency-2); $x++){
    if($setTime != 0){
      sleep($setTime);
    }
    else{
      sleep(1);
    }

    system"setMac($list_file_name $adapter_name)";
  }
}


#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

SwitchMac - provide tools to change the mac address

=head1 SYNOPSIS

  use SwitchMac;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Rafael Lucas
    CPAN ID: RAFALUCAS
    rafalucas@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

