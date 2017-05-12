package Utils;
use Readonly;
use Carp;
use Perl6::Slurp;
Readonly @CLASSES => (
    'CGI::Minimal',
    'CGI::Simple',
);

# TODO:
# Can we work with CGI::Lite::Request, Apache::Request?

sub get_cgi_modules {
    my @cgi_modules = (undef, 'CGI');
    foreach $class (@CLASSES) {
        eval "require $class";
        if (!$@) {
            push @cgi_modules, $class;
        }
    }
    return @cgi_modules;
}

sub get_expected {
    my $tcm = shift;
    my $name = shift;
    my @expected = $tcm->get_param(name=>$name);
    if (scalar(@expected) == 0) {
        croak 'where is the test data?';
    }
    my $is_file_upload = (ref $expected[0] eq 'HASH');
    if ($is_file_upload) {
        foreach my $e (@expected) {
            if (!exists $e->{type}) {
                $e->{type} = 'text/plain';
            }
            #if ($e->{type} eq 'text/plain') {
            #    $e->{value} = norm_eol($e->{value});
            #}
        }
    }
    return \@expected;
}

sub get_actual_upload {
    my $cgi = shift;
    my $name = shift;

    my @got;
    my $class = ref $cgi;

    if ($class eq 'CGI::Minimal') {
        my @fnames = $cgi->param_filename($name);
        my @data = $cgi->param($name);
        my @types = $cgi->param_mime($name);
        foreach my $i (@0..$#fnames) {
            push @got, {
                file=>$fnames[$i],
                value=>$data[$i],
                type=>$types[$i],
                name=>$name
            }
        }
    }
    elsif ($class eq 'CGI::Simple') {
        my @fh = $cgi->upload($name);
        foreach my $fh (@fh) {
            if ($fh) {
                my $data = slurp($fh);
                $fh->close;
                my $file = $cgi->param($name);
                my $type = $cgi->upload_info($file, 'mime');
                push @got, {
                    file=>$file,
                    value=>$data,
                    type=>$type,
                    name=>$name
                };
            }
            else {
                return undef;
            }
        }
    }
    else {
        my @fh = $cgi->upload($name);
        foreach my $fh (@fh) {
            if ($fh) {
                my $io = $fh->handle;
                my $data = slurp($io);
                $io->close;
                my $file = scalar $fh;
                #my $file = $cgi->param($name);
                my $type = $cgi->uploadInfo($file)->{'Content-Type'};
                push @got, {
                    file=>$file,
                    value=>$data,
                    type=>$type,
                    name=>$name
                };
            }
            else {
                return undef;
            }               
        }
    }
#    @got = sort { cmp_file($a,$b) } @got;

    return \@got;
}

sub cmp_file {
    my ($x, $y) = @_;
    return  $x->{file} cmp $y->{file};
};

sub norm_eol {
    my $text = shift;
    $text =~ s{\s*$}{\n}xmsg;
    $text =~ s{\s*\z}{}xms;
    return $text;
}

1
