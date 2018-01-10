package Pod::ProjectDocs::Config;

use strict;
use warnings;

our $VERSION = '0.50';    # VERSION

use Moose;

has 'title' => (
    is      => 'ro',
    default => "MyProject's Libraries",
    isa     => 'Str',
);

has 'desc' => (
    is      => 'ro',
    default => "manuals and libraries",
    isa     => 'Str',
);

has 'verbose' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'index' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'forcegen' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'nosourcecode' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'outroot' => (
    is  => 'ro',
    isa => 'Str',
);

has 'libroot' => (
    is  => 'ro',
    isa => 'ArrayRef[Str]'
);

has 'lang' => (
    is      => 'ro',
    default => 'en',
    isa     => 'Str',
);

has 'except' => (
    is  => 'ro',
    isa => 'ArrayRef[Str]'
);

1;
__END__
