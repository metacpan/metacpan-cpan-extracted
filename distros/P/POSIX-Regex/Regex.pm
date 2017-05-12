package POSIX::Regex;

use strict;
use warnings;
use Carp;

require Exporter;
use base 'Exporter';

our %EXPORT_TAGS = ( all => [qw(
    REG_EXTENDED
    REG_ICASE REG_NEWLINE
    REG_NOTBOL REG_NOTEOL
)]);

our @EXPORT_OK = ( @{$EXPORT_TAGS{all}} );
our @EXPORT = ();

our $VERSION = 1.0003;

# AUTOLOAD {{{
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&POSIX::Regex::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}
# }}}

require XSLoader;
XSLoader::load('POSIX::Regex', $VERSION);

sub new {
    my $class = shift;
    my $this  = bless {}, $class;
       $this->{rt} = shift || "";

    my $opts = 0;
       $opts |= $_ for @_;

    $this->regcomp($this->{rt}, $opts);

    return $this;
}

sub match {
    my $this = shift;
    my $str  = shift;

    my $opts = 0;
       $opts |= $_ for @_;

    return @{$this->regexec_wa( $str, $opts )} if wantarray;
    return $this->regexec( $str, $opts );
}

sub DESTROY { my $this = shift; $this->cleanup_memory; }

1;
