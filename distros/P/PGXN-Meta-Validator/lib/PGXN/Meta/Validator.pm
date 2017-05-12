package PGXN::Meta::Validator;

use 5.010;
use strict;
use warnings;
use SemVer;
use JSON;
use Carp qw(croak);
our $VERSION = v0.16.0;

=head1 Name

PGXN::Meta::Validator - Validate PGXN distribution metadata structures

=head1 Synopsis

  my $struct = decode_json_file('META.json');

  my $pmv = PGXN::Meta::Validator->new( $struct );

  unless ( $pmv->is_valid ) {
      my $msg = "Invalid META structure. Errors found:\n";
      $msg .= join( "\n", $pmv->errors );
      die $msg;
  }

=head1 Description

This module validates a PGXN Meta structure against the version of the the
specification claimed in the C<meta-spec> field of the structure. Currently,
there is only v1.0.0.

=cut

#--------------------------------------------------------------------------#
# This code copied and adapted from CPAN::Meta::Valicator by
# David Golden <dagolden@cpan.org> and Ricardo Signes <rjbs@cpan.org>,
# which in turn adapted and copied it from Test::CPAN::Meta
# by Barbie, <barbie@cpan.org> for Miss Barbell Productions,
# L<http://www.missbarbell.co.uk>
#--------------------------------------------------------------------------#

#--------------------------------------------------------------------------#
# Specification Definitions
#--------------------------------------------------------------------------#

my %known_specs = (
    '1.0.0' => 'http://pgxn.org/spec/1.0.0/'
);
my %known_urls = map {$known_specs{$_} => $_} keys %known_specs;

my $no_index = {
    'map'       => { file       => { list => { value => \&string } },
                     directory  => { list => { value => \&string } },
                    ':key'      => { name => \&custom, value => \&anything },
    }
};

my $prereq_map = {
  map => {
    ':key' => {
      name => \&phase,
      'map' => {
        ':key'  => {
          name => \&relation,
          'map' => { ':key' => { name => \&term, value => \&exversion } }
        },
      },
    }
  },
};

my %definitions = (
    '1.0.0' => {
        # REQUIRED
        'abstract'            => { mandatory => 1, value => \&string  },
        'maintainer'          => { mandatory => 1, list => { value => \&string } },
        'generated_by'        => { mandatory => 0, value => \&string  },
        'license'             => {
            mandatory => 1,
            listormap => {
                list => { value => \&license },
                map => {
                    ':key' => { name => \&anything, value => \&url }
                },
            }
        },
        'meta-spec' => {
            mandatory => 1,
            'map' => {
                version => { mandatory => 1, value => \&version},
                url     => { value => \&url },
                ':key' => { name => \&custom, value => \&anything },
            }
        },
        'name'                => { mandatory => 1, value => \&term  },
        'release_status'      => { mandatory => 0, value => \&release_status },
        'version'             => { mandatory => 1, value => \&version },
        'provides'    => {
            'mandatory' => 1,
            'map'       => {
                ':key' => {
                    name  => \&term,
                    'map' => {
                        file     => { mandatory => 1, value => \&file },
                        version  => { mandatory => 1, value => \&version },
                        abstract => { mandatory => 0, value => \&string  },
                        docfile  => { mandatory => 0, value => \&file },
                        ':key' => { name => \&custom, value => \&anything },
                    }
                }
            }
        },

        # OPTIONAL
        'description' => { value => \&string },
        'tags'    => { list => { value => \&tag } },
        'no_index' => $no_index,
        'prereqs' => $prereq_map,
        'resources'   => {
            'map'       => {
                license    => { list => { value => \&url } },
                homepage   => { value => \&url },
                bugtracker => {
                    'map' => {
                        web => { value => \&url },
                        mailto => { value => \&email},
                        ':key' => { name => \&custom, value => \&anything },
                    }
                },
                repository => {
                    'map' => {
                        web => { value => \&url },
                        url => { value => \&url },
                        type => { value => \&lc_string },
                        ':key' => { name => \&custom, value => \&anything },
                    }
                },
                ':key'     => { value => \&string, name => \&custom },
            }
        },

        # CUSTOM -- additional user defined key/value pairs
        # note we can only validate the key name, as the structure is user defined
        ':key'        => { name => \&custom, value => \&anything },
    },
);

#--------------------------------------------------------------------------#
# Code
#--------------------------------------------------------------------------#

=head1 Interface

=head2 Constructors

=head3 C<new>

  my $pmv = PGXN::Meta::Validator->new( $struct )

The constructor must be passed a metadata structure.

=cut

sub new {
  my ($class, $data) = @_;

  # create an attributes hash
  my $self = {
    'data'    => $data,
    'spec'    => $data->{'meta-spec'} && $data->{'meta-spec'}{version}
               ? $data->{'meta-spec'}{version}
               : '1.0.0',
    'errors'  => undef,
  };

  # create the object
  return bless $self, $class;
}

=head3 C<load_file>

  my $meta = PGXN::Meta::Validator->load_file('META.json');

Reads in the specified JSON file and passes the resulting data structure to
C<new()>, returning the resulting PGXN::Meta::Validator object. An exception
will be thrown if the file does not exist or if its contents are not valid
JSON.

=cut

sub load_file {
    my ($class, $file) = @_;

    croak "load_file() requires a valid, readable filename"
        unless -r $file;

    $class->new(JSON->new->decode(do {
        local $/;
        open my $fh, '<:raw', $file or croak "Cannot open $file: $!\n";
        <$fh>;
    }));
}

=head2 Class Method

=head3 C<version_string>

  say 'PGXN::Meta::Validator ', PGXN::Meta::Validator->version_string;

Returns a string representation of the PGXN::Meta::Validator version.

=cut

sub version_string {
    sprintf 'v%vd', $VERSION;
}

=head2 Instance Methods

=head3 C<is_valid>

  if ( $pmv->is_valid ) {
    ...
  }

Returns a boolean value indicating whether the metadata provided
is valid.

=cut

sub is_valid {
    my $self = shift;
    my $data = $self->{data};
    my $spec_version = $self->{spec};
    $self->check_map($definitions{$spec_version}, $data);
    return ! $self->errors;
}

=head3 C<errors>

  warn( join "\n", $pmv->errors );

Returns a list of errors seen during validation.

=cut

sub errors {
    my $self = shift;
    return () unless defined $self->{errors};
    return @{$self->{errors}};
}

=begin internals

=head2 Check Methods

=over

=item * check_map($spec,$data)

Checks whether a map (or hash) part of the data structure conforms to the
appropriate specification definition.

=item * check_list($spec,$data)

Checks whether a list conforms, but converts strings to a single-element list

=item * check_listormap($spec,$data)

Checks whether a map or lazy list conforms to the appropriate specification
definition.

=back

=cut

my $spec_error = "Missing validation action in specification. "
  . "Must be one of 'map', 'list', or 'value'";

sub check_map {
    my ($self,$spec,$data) = @_;

    if(ref($spec) ne 'HASH') {
        $self->_error( "Unknown META specification, cannot validate." );
        return;
    }

    if(ref($data) ne 'HASH') {
        $self->_error( 'Should be a map structure' );
        return;
    }

    for my $key (keys %$spec) {
        next    unless($spec->{$key}->{mandatory});
        next    if(defined $data->{$key});
        push @{$self->{stack}}, $key;
        $self->_error( 'missing', 'Required field' );
        pop @{$self->{stack}};
    }

    for my $key (keys %$data) {
        push @{$self->{stack}}, $key;
        if($spec->{$key}) {
            if($spec->{$key}{value}) {
                $spec->{$key}{value}->($self,$key,$data->{$key});
            } elsif($spec->{$key}{'map'}) {
                $self->check_map($spec->{$key}{'map'},$data->{$key});
            } elsif($spec->{$key}{'list'}) {
                $self->check_list($spec->{$key}{'list'},$data->{$key});
            } elsif($spec->{$key}{'listormap'}) {
                $self->check_listormap($spec->{$key}{'listormap'},$data->{$key});
            } else {
                $self->_error( "$spec_error for '$key'" );
            }

        } elsif ($spec->{':key'}) {
            $spec->{':key'}{name}->($self,$key,$key);
            if($spec->{':key'}{value}) {
                $spec->{':key'}{value}->($self,$key,$data->{$key});
            } elsif($spec->{':key'}{'map'}) {
                $self->check_map($spec->{':key'}{'map'},$data->{$key});
            } elsif($spec->{':key'}{'list'}) {
                $self->check_list($spec->{':key'}{'list'},$data->{$key});
            } elsif($spec->{':key'}{'listormap'}) {
                $self->check_listormap($spec->{':key'}{'listormap'},$data->{$key});
            } else {
                $self->_error( "$spec_error for ':key'" );
            }


        } else {
            $self->_error( "Unknown key, '$key', found in map structure" );
        }
        pop @{$self->{stack}};
    }
}

# if it's a string, make it into a list and check the list
sub check_list {
    my ($self,$spec,$data) = @_;

    if ( defined $data && ! ref $data) {
        $self->_list_value($spec, $data);
    } else {
        $self->_error( 'Should be a list structure' ) if ref $data ne 'ARRAY';
        $self->_error( "Missing entries from required list" )
            if defined $spec->{mandatory} && !defined $data->[0];
        my $field = pop @{ $self->{stack} };
        my $i = 0;
        for my $value (@{ $data }) {
            push @{$self->{stack}}, $field . "[$i]";
            $i++;
            $self->_list_value($spec, $value);
            pop @{$self->{stack}};
        }
        push @{$self->{stack}}, $field;
    }
}

sub _list_value {
    my ($self, $spec, $value) = @_;
    if(defined $spec->{value}) {
        $spec->{value}->($self,'list',$value);
    } elsif(defined $spec->{'map'}) {
        $self->check_map($spec->{'map'},$value);
    } elsif(defined $spec->{'list'}) {
        $self->check_list($spec->{'list'},$value);
    } elsif(defined $spec->{'list'}) {
        $self->check_list($spec->{'list'},$value);
    } elsif(defined $spec->{'listormap'}) {
        $self->check_listormap($spec->{'listormap'},$value);
    } elsif ($spec->{':key'}) {
        $self->check_map($spec,$value);
    } else {
        $self->_error( "$spec_error associated with '$self->{stack}[-2]'" );
    }
}

sub check_listormap {
    my ($self,$spec,$data) = @_;

    return ref $data eq 'HASH'
        ? $self->check_map($spec->{map}, $data)
        : $self->check_list($spec->{list}, $data);
}

=head2 Validator Methods

=over

=item * anything($self,$key,$value)

Any value is valid, so this function always returns true.

=item * url($self,$key,$value)

Validates that a given value is in an acceptable URL format

=item * email($self,$key,$value)

Validates that a given value is in an acceptable EMAIL format

=item * urlspec($self,$key,$value)

Validates that the URL to a META specification is a known one.

=item * string_or_undef($self,$key,$value)

Validates that the value is either a string or an undef value. Bit of a
catchall function for parts of the data structure that are completely user
defined.

=item * string($self,$key,$value)

Validates that a string exists for the given key.

=item * lc_string($self,$key,$value)

Validates that a string exists for the given key and contains only lowercase
characters.

=item * file($self,$key,$value)

Validate that a file is passed for the given key. This may be made more
thorough in the future. For now it acts like \&string.

=item * phase($self,$key,$value)

Validate that a prereq phase is one of "configure", "build", "test",
"runtime", or "develop".

=item * relation($self,$key,$value)

Validate that a prereq relation is one of "requires", "recommends",
"suggests", or "conflicts".

=item * release_status($self,$key,$value)

Validate that release status is one of "stable", "testing", or "unstable".

=item * exversion($self,$key,$value)

Validates a list of versions, e.g. '<= 5, >=2, ==3, !=4, >1, <6, 0'.

=item * version($self,$key,$value)

Validates a single version string. Versions of the type '5.8.8' and '0.00_00'
are both valid. A leading 'v' like 'v1.2.3' is also valid.

=item * boolean($self,$key,$value)

Validates for a boolean value. Currently these values are '1', '0', 'true',
'false', however the latter 2 may be removed.

=item * license($self,$key,$value)

Validates that a value is given for the license. Returns 1 if an known license
type, or 2 if a value is given but the license type is not a recommended one.

=item * custom($self,$key,$value)

Validates that the given key begins with 'x_' or 'X_', to indicate a user
defined tag and only has characters in the class [-_a-zA-Z]

=item * identifier($self,$key,$value)

Validates that key is in an acceptable format for the META specification,
for an identifier, i.e. any that matches the regular expression
qr/[a-z][a-z_]/i.

=item * term($self,$key,$value)

Validates that a given value is in an acceptable term, i.e., at least two
characters and does not contain control characters, spaces, C</>, or C<\>.

=item * tag($self,$key,$value)

Validates that a given value is in an acceptable tag, i.e., between 1 and 256
characters and does not contain control characters, C</>, or C<\>.

=back

=end internals

=cut

sub release_status {
  my ($self,$key,$value) = @_;
  $value = '' unless defined $value;
  return 1 if $value =~ /\A(?:(?:un)?stable|testing)\z/;
  $self->_error( qq{"$value" is not a valid release status; must be one of stable, testing, unstable} );
  return 0;
}

# _uri_split taken from URI::Split by Gisle Aas, Copyright 2003
sub _uri_split {
     return $_[0] =~ m,(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?,;
}

sub url {
    my ($self,$key,$value) = @_;
    if (defined $value && $value ne '') {
      # XXX Consider using Data::Validate::URI.
      my ($scheme, $auth, $path, $query, $frag) = _uri_split($value);
      unless ( defined $scheme && length $scheme ) {
        $self->_error( qq{"$value" is not a valid URL} );
        return 0;
      }
      unless ( defined $auth && length $auth ) {
        $self->_error( qq{"$value" is not a valid URL} );
        return 0;
      }
      return 1;
    } else {
        $self->_error('No value');
        return 0;
    }
    $self->_error( qq{"$value" is not a valid URL} );
    return 0;
}

sub urlspec {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1    if($value && $known_specs{$self->{spec}} eq $value);
        if($value && $known_urls{$value}) {
            $self->_error( 'META specification URL does not match version' );
            return 0;
        }
    }
    $self->_error( 'Unknown META specification' );
    return 0;
}

sub email {
    my ($self, $key, $value) = @_;
    # XXX Consider using Email::Valid.
    return 1 if defined $value && $value =~ /@/;
    $self->_error( qq{"$value" is not a valid email address} );
    return 0;
}

sub anything { return 1 }

sub string {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1    if($value || $value =~ /^0$/);
    }
    $self->_error( "No value" );
    return 0;
}

sub lc_string {
    my ($self, $key, $value) = @_;
    $self->string($key, $value) or return 0;
    return 1 if $value !~ /\p{Upper}/;
    $self->_error( qq{"$value" is not a lowercase string} );
    return 0;
}

sub term {
    shift->_string_class(@_, term => qr{[[:space:][:cntrl:]/\\]}, 2);
}

sub tag {
    shift->_string_class(@_, tag => qr{[[:cntrl:]/\\]}, 1, 256);
}

sub _string_class {
    my ($self, $key, $value, $type, $regex, $min, $max) = @_;
    unless (defined $value) {
        $self->_error( 'value is not defined' );
        return 0;
    }

    if (($value || $value =~ /^0$/) && $value !~ $regex) {
        if ($min && length $value < $min) {
            $self->_error("$type must be at least $min characters");
            return 0;
        }
        if ($max && length $value > $max) {
            $self->_error("$type must be no more than $max characters");
            return 0;
        }
        return 1;
    } else {
        $self->_error(qq{"$value" is not a valid $type});
        return 0;
    }
}

sub string_or_undef {
    my ($self,$key,$value) = @_;
    return 1    unless(defined $value);
    return 1    if($value || $value =~ /^0$/);
    $self->_error( "No string defined for '$key'" );
    return 0;
}

sub file {
    my ($self,$key,$value) = @_;
    return 1    if(defined $value);
    $self->_error( 'No value' );
    return 0;
}

sub exversion {
    my ($self,$key,$value) = @_;
    if (defined $value && ($value || $value eq '0')) {
        my $pass = 1;
        for my $val (split /,\s*/, $value) {
            if ($val ne '') {
                next if $val eq '0';
                if ($val =~ s/^([^\d\s]+)\s*//) {
                    my $op = $1;
                    if ($op !~ /^[<>](?:=)?|==|!=$/) {
                        $self->_error(qq{"$op" is not a valid version range operator});
                        $pass = 0;
                    }
                }
                unless (eval { SemVer->new($val) }) {
                        # Field /version: Value "0.01.2" is not a valid version [Spec v1.0.0]
                    $self->_error( qq{"$val" is not a valid semantic version} );
                    $pass = 0;
                }
            } else {
                $self->_error( qq{"" is not a valid semantic version} );
                $pass = 0;
            }
        }
        return $pass;
    }
    $self->_error($value ? qq{value "$value" is not a valid semantic version} : 'No value' );
    return 0;
}

sub version {
    my ($self,$key,$value) = @_;
    if (defined $value) {
        return 1    if eval { SemVer->new($value) };
    } else {
        $value = '<undef>';
    }
   $self->_error( qq{"$value" is not a valid semantic version} );
    return 0;
}

sub boolean {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1    if($value =~ /^(0|1|true|false)$/);
    } else {
        $value = '<undef>';
    }
    $self->_error( "'$value' for '$key' is not a boolean value." );
    return 0;
}

my %licenses = map { $_ => 1 } qw(
    agpl_3
    apache_1_1
    apache_2_0
    artistic_1
    artistic_2
    bsd
    freebsd
    gfdl_1_2
    gfdl_1_3
    gpl_1
    gpl_2
    gpl_3
    lgpl_2_1
    lgpl_3_0
    mit
    mozilla_1_0
    mozilla_1_1
    openssl
    perl_5
    postgresql
    qpl_1_0
    ssleay
    sun
    zlib
    open_source
    restricted
    unrestricted
    unknown
);

sub license {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1 if $value && exists $licenses{$value};
    } else {
        $value = '<undef>';
    }
    $self->_error( qq{"$value" is an unknown license} );
    return 0;
}

sub custom {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1    if($key && $key =~ /^x_/i);  # user defined
    } else {
        $key = '<undef>';
    }
    $self->_error( 'Unknown key; custom keys must begin with "x_" or "X_"' );
    return 0;
}

sub identifier {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1    if($key && $key =~ /^([a-z][_a-z]+)$/i);    # spec 2.0 defined
    } else {
        $key = '<undef>';
    }
    $self->_error( "Key '$key' is not a legal identifier." );
    return 0;
}

my @valid_phases = qw/ configure build test runtime develop /;
sub phase {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1 if( length $key && grep { $key eq $_ } @valid_phases );
        return 1 if $key =~ /x_/i;
    }
    $self->_error('Unknown preqreq phase; must be one of ' . join ', ', @valid_phases);
    return 0;
}

my @valid_relations = qw/ requires recommends suggests conflicts/;
sub relation {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1 if( length $key && grep { $key eq $_ } @valid_relations );
        return 1 if $key =~ /x_/i;
    }
    $self->_error('Unknown preqreq relationship; must be one of ' . join ', ', @valid_relations);
    return 0;
}

sub _error {
    my $self = shift;
    my $mess = shift;
    my $label = shift || 'Field';

    $mess = "$label /" . join( '/' => @{ $self->{stack} }) . ": $mess" if $self->{stack};
    $mess .= " [Spec v$self->{spec}]";

    push @{$self->{errors}}, $mess;
}

1;

__END__

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/pgxn/pgxn-meta/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/pgxn/pgxn-meta/issues/> or by sending mail to
L<bug-PGXN-Meta@rt.cpan.org|mailto:bug-PGXN-Meta@rt.cpan.org>.

=cut

# '0.01.2' for 'version' is not a valid version. (provides -> pair -> version) [Validation: 1.0.0]
# Field /provides/pair/version: Value "0.01.2" is not a valid version [Spec v1.0.0]
# Field /version: Value "0.01.2" is not a valid version [Spec v1.0.0]
# Field /name: Missing mandatory field [Spec v1.0.0]",

