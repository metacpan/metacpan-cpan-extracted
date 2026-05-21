package Pheno::Ranker::Config;

use strict;
use warnings;

use Hash::Util qw(lock_hash);
use Moo;
use Types::Standard qw(ArrayRef Enum HashRef Int Str);

use Pheno::Ranker::IO;

has file => (
    is       => 'ro',
    required => 1,
    isa      => sub { die "Config file '$_[0]' is not a valid file" unless -e $_[0] },
);

has raw => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_raw',
);

has sort_by => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{sort_by} ? $self->raw->{sort_by} : 'hamming';
    },
    isa     => Enum [qw(hamming jaccard)],
);

has similarity_metric_cohort => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{similarity_metric_cohort}
          ? $self->raw->{similarity_metric_cohort}
          : 'hamming';
    },
    isa     => Enum [qw(hamming jaccard)],
);

has matrix_format => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{matrix_format}
          ? $self->raw->{matrix_format}
          : 'dense';
    },
    isa     => Enum [qw(dense mtx)],
);

has max_out => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{max_out} ? $self->raw->{max_out} : 50;
    },
    isa     => Int,
);

has max_number_vars => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{max_number_vars}
          ? $self->raw->{max_number_vars}
          : 10_000;
    },
    isa     => Int,
);

has max_matrix_records_in_ram => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{max_matrix_records_in_ram}
          ? $self->raw->{max_matrix_records_in_ram}
          : 5_000;
    },
    isa     => Int,
);

has allowed_terms => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->raw->{allowed_terms} },
    isa     => ArrayRef,
);

has primary_key => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{primary_key} ? $self->raw->{primary_key} : 'id';
    },
);

has exclude_variables_regex => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{exclude_variables_regex}
          ? $self->raw->{exclude_variables_regex}
          : undef;
    },
);

has exclude_variables_regex_qr => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $regex = shift->exclude_variables_regex;
        return defined $regex ? qr/$regex/ : undef;
    },
);

has array_terms => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_config_value( 'indexed_terms', 'array_terms' ) // ['foo'];
    },
    isa     => ArrayRef,
);

has array_regex => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return defined $self->_config_value( 'index_regex', 'array_regex' )
          ? $self->_config_value( 'index_regex', 'array_regex' )
          : '^([^:]+):(\d+)';
    },
);

has array_regex_qr => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $regex = shift->array_regex;
        return qr/$regex/;
    },
);

has array_terms_regex_str => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return '^(' . join( '|', map { "\Q$_\E" } @{ $self->array_terms } ) . '):';
    },
);

has array_terms_regex_qr => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $regex = shift->array_terms_regex_str;
        return qr/$regex/;
    },
);

has format => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->raw->{format} ? $self->raw->{format} : undef;
    },
);

has seed => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $seed = exists $self->raw->{seed} ? $self->raw->{seed} : undef;
        return defined $seed && Int->check($seed) ? $seed : 123456789;
    },
    isa => Int,
);

has id_correspondence => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_config_value( 'identity_paths', 'id_correspondence' );
    },
);

sub _config_value {
    my ( $self, $primary, $legacy ) = @_;
    return $self->raw->{$primary} if exists $self->raw->{$primary};
    return $self->raw->{$legacy}  if defined $legacy && exists $self->raw->{$legacy};
    return undef;
}

sub BUILD {
    my $self = shift;
    $self->raw;
    $self->_validate_id_correspondence;
}

sub _build_raw {
    my $self   = shift;
    my $config = read_yaml( $self->file );

    unless ( exists $config->{allowed_terms}
        && ArrayRef->check( $config->{allowed_terms} )
        && @{ $config->{allowed_terms} } )
    {
        die "No <allowed terms> provided or not an array ref at " . $self->file . "\n";
    }

    lock_hash(%$config);
    return $config;
}

sub _validate_id_correspondence {
    my $self = shift;
    return if $self->array_terms->[0] eq 'foo';

    unless ( defined $self->id_correspondence ) {
        return if defined $self->format && $self->format eq 'JSON';
        die "No <identity_paths> provided or not a hash ref at " . $self->file . "\n";
    }

    die "No <identity_paths> provided or not a hash ref at " . $self->file . "\n"
      unless HashRef->check( $self->id_correspondence );

    if ( exists $self->raw->{format} && Str->check( $self->raw->{format} ) ) {
        die "<" . $self->raw->{format} . "> does not match any key from <identity_paths>\n"
          unless exists $self->id_correspondence->{ $self->raw->{format} };
    }
}

sub validate_terms {
    my ( $self, @terms ) = @_;

    for my $term (@terms) {
        die
"Invalid term '$term' in <--include_terms> or <--exclude_terms>. Allowed values are: "
          . join( ', ', @{ $self->allowed_terms } ) . "\n"
          unless grep { $_ eq $term } @{ $self->allowed_terms };
    }

    return 1;
}

sub apply_to {
    my ( $self, $ranker ) = @_;

    for my $attribute (
        qw(
        primary_key exclude_variables_regex exclude_variables_regex_qr
        array_terms array_regex array_regex_qr array_terms_regex_str
        array_terms_regex_qr format seed id_correspondence
        )
      )
    {
        $ranker->{$attribute} = $self->$attribute;
    }

    return 1;
}

1;
