package Pod::ProjectDocs::Config;

use strict;
use warnings;

our $VERSION = '0.48'; # VERSION

use base qw/Class::Accessor::Fast/;

use Readonly;

__PACKAGE__->mk_accessors(qw/
    title
    desc
    verbose
    index
    outroot
    libroot
    forcegen
    lang
    except
/);

Readonly my $DEFAULT_TITLE   => qq/MyProject's Libraries/;
Readonly my $DEFAULT_DESC    => qq/manuals and libraries/;
Readonly my $DEFAULT_LANG    => qq/en/;

sub new {
    my ($class, @args) = @_;
    my $self  = bless { }, $class;
    $self->_init(@args);
    return $self;
}

sub _init {
    my($self, %args) = @_;
    $self->title   ( $args{title}   || $DEFAULT_TITLE   );
    $self->desc    ( $args{desc}    || $DEFAULT_DESC    );
    $self->lang    ( $args{lang}    || $DEFAULT_LANG    );
    $self->verbose ( $args{verbose}                     );
    $self->index   ( $args{index}                       );
    $self->outroot ( $args{outroot}                     );
    $self->libroot ( $args{libroot}                     );
    $self->forcegen( $args{forcegen}                    );
    $self->except  ( $args{except}                      );
    return;
}

1;
__END__
