
package POD2::Base;

use 5.005;
use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = '0.043';

use File::Spec ();

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $obj = bless {}, $class;
    return $obj->_init( @_ );
}

# instance variables:
#   lang - the preferred language of the POD documents
#   inc - alternate library dirs (if given, replaces the ones in @INC)

sub _init {
    my $self = shift;
    my %args = @_ ? %{$_[0]} : ();
    if ( !exists $args{lang} ) {
        $args{lang} = _extract_lang( ref $self );
    }
    #croak "???" unless $args{lang};
    my $lang = uc $args{lang};
    $self->{lang} = $lang;
    $self->{inc} = $args{inc}; # XXX croak ?! must be array ref

    return $self;
}

# $lang = _extract_lang($module);
sub _extract_lang {
    my $module = shift;

    return $module eq __PACKAGE__  ? undef
         : $module =~ /::(\w+)\z/  ? $1
         :                           undef
         ;
}

sub _lib_dirs {
    my $self = shift;
    return $self->{inc} ? @{$self->{inc}} : @INC;
}

sub pod_dirs {
    my $self = shift;
    my %options = @_ ? %{$_[0]} : ();
    $options{test} = 1 unless exists $options{test};

    my $lang = $self->{lang};
    my @candidates = map { File::Spec->catdir( $_, 'POD2', $lang ) } $self->_lib_dirs; # XXX the right thing to do
    if ( $options{test} ) {
        return grep { -d } @candidates;
    }
    return @candidates;
}

#sub search_perlfunc_re {
#    shift;
#    return 'Alphabetical Listing of Perl Functions';
#}

sub pod_info {
    shift;
    return {};
}

sub print_pods {
    my $self = shift;
    $self->print_pod(sort keys %{$self->pod_info});
}

sub print_pod {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;

    my $pods = $self->pod_info;
    while (@args) {
        (my $pod = lc(shift @args)) =~ s/\.pod$//;
        if ( exists $pods->{$pod} ) {
            print "\t'$pod' translated from Perl $pods->{$pod}\n";
        }
        else {
            print "\t'$pod' doesn't yet exists\n";
        }
    }
}

1;
