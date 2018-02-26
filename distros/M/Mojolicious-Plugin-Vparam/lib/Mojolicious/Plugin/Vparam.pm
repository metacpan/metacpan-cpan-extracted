package Mojolicious::Plugin::Vparam;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::Vparam::Common qw(:all);

use version;
use List::MoreUtils qw(firstval natatime mesh);

our $VERSION    = '3.04';

# Regext for shortcut parser
our $SHORTCUT_REGEXP = qr{
    ^
    (
        [!?@~%]                                         # symbols shortcut
        |
        (?:array|maybe|optional|required?|skipundef)\[  # text[] shortcut start
    )
    (.*?)                                               # value
    \]?                                                 # text[] shortcut end
    $
}xi;

sub register {
    my ($self, $app, $conf) = @_;

    $conf                   ||= {};

    $conf->{class}          ||= 'field-with-error';
    $conf->{types}          ||= {};
    $conf->{filters}        ||= {};

    $conf->{vsort_page}     ||= 'page';
    $conf->{vsort_rws}      ||= 'rws';
    $conf->{rows}           ||= 25;
    $conf->{vsort_oby}      ||= 'oby';
    $conf->{vsort_ods}      ||= 'ods';
    $conf->{ods}            ||= 'ASC';

    $conf->{phone_country}  //= '';
    $conf->{phone_region}   //= '';
    $conf->{phone_fix}      //= '';

    $conf->{date}           = '%F'          unless exists $conf->{date};
    $conf->{time}           = '%T'          unless exists $conf->{time};
    $conf->{datetime}       = '%F %T %z'    unless exists $conf->{datetime};

    $conf->{blessed}        //= 1;
    $conf->{optional}       //= 0;
    $conf->{skipundef}      //= 0;
    $conf->{multiline}      //= 0;

    $conf->{address_secret} //= '';

    $conf->{password_min}   //= 8;

    $conf->{hash_delimiter} //= '=>';

    # Enable Mojolicious::Validator::Validation integration if available
    $conf->{mojo_validator} //=
        version->new($Mojolicious::VERSION) < version->new(4.42) ? 0 : 1;

    # Get or set type
    $app->helper(vtype => sub {
        my ($self, $name, %opts) = @_;
        return $conf->{types}{$name} = \%opts if @_ > 2;
        return $conf->{types}{$name};
    });

    # Get or set filter
    $app->helper(vfilter => sub {
        my ($self, $name, $sub) = @_;
        return $conf->{filters}{$name} = $sub if @_ > 2;
        return $conf->{filters}{$name};
    });

    # Get or set config parameters
    $app->helper(vconf => sub {
        my ($self, $name, $value) = @_;
        return $conf->{$name} = $value if @_ > 2;
        return $conf->{$name};
    });

    # Get or set error for parameter $name
    $app->helper(verror => sub{
        my ($self, $name, @opts) = @_;

        my $errors = $self->stash->{'vparam-verrors'} //= {};

        if( @_ <= 2 ) {
            return 0 unless exists $errors->{$name};

            return 'ARRAY' eq ref $errors->{$name}
                ? scalar @{$errors->{$name}}
                : $errors->{$name}{message} // 0
            ;
        } elsif( @_ == 3 ) {
            return 0 unless exists $errors->{$name};

            my $error = 'ARRAY' eq ref $errors->{$name}
                ? firstval {$_->{index} == $opts[0]} @{$errors->{$name}}
                : $errors->{$name}
            ;
            return $error->{message} // 0;
        } else {

            my %attr = %{{@opts}};
            if( $attr{array} ) {
                $errors->{ $name } = [] unless exists $errors->{ $name };
                push @{$errors->{ $name }}, \%attr;
            } else {
                $errors->{ $name } = \%attr;
            }

            if( $conf->{mojo_validator} ) {
                $self->validation->error($name => [$attr{message}]);
            }

            return $errors;
        }
    });

    # Return string if parameter have error, else empty string.
    $app->helper(vclass => sub{
        my ($self, $name, @classes) = @_;
        return '' unless $self->verror( $name );

        my @class;
        push @class, $conf->{class}
            if defined($conf->{class}) && length($conf->{class});
        push @class, @classes;

        return join ' ', @class;
    });

    $app->helper(vvalue => sub{
        my ($self, $name, $default) = @_;

        my @input = params($self, $name);

        my $value;
        if( not @input ) {
            $value = $default;
        } elsif( @input > 1 ) {
            $value = \@input;
        } else {
            $value = $input[0];
        }

        return $value;
    });

    # Return all errors as Hash or errors count in scalar context.
    $app->helper(verrors => sub{
        my ($self) = @_;
        my $errors = $self->stash->{'vparam-verrors'} //= {};
        return wantarray ? %$errors : scalar keys %$errors;
    });

    # Many parameters
    $app->helper(vparams => sub{
        my ($self, %params) = @_;

        # Result
        my %result;

        # Get default optional
        my $optional = exists $params{-optional}
            ? delete $params{-optional}
            : $conf->{optional}
        ;
        my $skipundef = exists $params{-skipundef}
            ? delete $params{-skipundef}
            : $conf->{skipundef}
        ;
        my $multiline = exists $params{-multiline}
            ? delete $params{-multiline}
            : $conf->{multiline}
        ;
        my $blessed = exists $params{-blessed}
            ? delete $params{-blessed}
            : $conf->{blessed}
        ;

        # Internal variables
        my $vars = $self->stash->{'vparam-vars'} //= {};

        for my $name (keys %params) {
            # Param definition
            my $def = $params{$name};

            # Get attibutes
            my %attr;
            if( 'HASH' eq ref $def ) {
                %attr           = %$def;
            } elsif( 'Regexp' eq ref $def ) {
                $attr{regexp}   = $def;
            } elsif( 'CODE' eq ref $def ) {
                $attr{post}     = $def;
            } elsif( 'ARRAY' eq ref $def ) {
                $attr{in}       = $def;
            } elsif( !ref $def ) {
                $attr{type}     = $def;
            }

            # Skip
            if( exists $attr{skip} ) {
                if( 'CODE' eq ref $attr{skip} ) {
                    # Skip by sub result
                    next if $attr{skip}->($self, $name);
                } elsif( $attr{skip} ) {
                    # Skip by flag
                    next;
                }
            }

            # Set defaults
            $attr{optional}     //= $optional;
            $attr{skipundef}    //= $skipundef;
            $attr{multiline}    //= $multiline;
            $attr{blessed}      //= $blessed;

            # Apply type
            my $type = $attr{type} // $attr{isa};
            if( defined $type ) {
                # Parse shortcut
                while( my ($mod, $inner) = $type =~ $SHORTCUT_REGEXP ) {
                    last unless $inner;
                    $type = $inner;

                    if(      $mod eq '?' || $mod =~ m{^optional\[}i) {
                        $attr{optional} = 1;
                    } elsif( $mod eq '!' || $mod =~ m{^required?\[}i) {
                        $attr{optional} = 0;
                    } elsif( $mod eq '@' || $mod =~ m{^array\[}i) {
                        $attr{array}    = 1;
                    } elsif( $mod eq '%' ) {
                        $attr{hash}     //= $conf->{hash_delimiter};
                    } elsif(                $mod =~ m{^skipundef\[}i) {
                        $attr{skipundef}= 1;
                    } elsif( $mod eq '~' ) {
                        $attr{skipundef}= 1;
                        $attr{optional} = 1;
                    }
                }

                if( exists $conf->{types}{ $type } ) {
                    for my $key ( keys %{$conf->{types}{ $type }} ) {
                        next if defined $attr{ $key };
                        $attr{ $key } = $conf->{types}{ $type }{ $key };
                    }
                } else {
                    die sprintf 'Type "%s" is not defined', $type;
                }
            }

            # Preload module if required
            if( my $load = $attr{load} ) {
                if( 'CODE' eq ref $load ) {
                    $load->($self, $name);
                } elsif( 'ARRAY' eq ref $load ) {
                    for my $module ( @$load ) {
                        my $e = load_class( $module );
                        die $e if $e;
                    }
                } else {
                    my $e = load_class( $load );
                    die $e if $e;
                }
            }

            # Get value
            my @input;
            if ($attr{'jpath?'}) {
                # JSON Pointer
                unless (exists $vars->{json}) {
                    $vars->{json} =
                        Mojolicious::Plugin::Vparam::JSON::parse_json(
                            $self->req->body // ''
                        );
                }
                if( $vars->{json} ) {
                    $vars->{pointer} //=
                        Mojo::JSON::Pointer->new( $vars->{json} );
                    if( $vars->{pointer}->contains( $attr{'jpath?'} ) ) {
                        my $value = $vars->{pointer}->get( $attr{'jpath?'} );
                        @input = 'ARRAY' eq ref $value ? @$value : $value;
                    }
                } else {
                    # POST parameters
                    @input = params($self, $name);
                }
            } elsif ($attr{jpath}) {
                # JSON Pointer
                unless (exists $vars->{json}) {
                    $vars->{json} =
                        Mojolicious::Plugin::Vparam::JSON::parse_json(
                            $self->req->body // ''
                        );
                }
                if( $vars->{json} ) {
                    $vars->{pointer} //=
                        Mojo::JSON::Pointer->new( $vars->{json} );
                    if( $vars->{pointer}->contains( $attr{jpath} ) ) {
                        my $value = $vars->{pointer}->get( $attr{jpath} );
                        @input = 'ARRAY' eq ref $value ? @$value : $value;
                    }
                }
            } elsif ($attr{cpath}) {
                # CSS
                unless (exists $vars->{dom}) {
                    $vars->{dom} =
                        Mojolicious::Plugin::Vparam::DOM::parse_dom(
                            $self->req->body // ''
                        );
                }
                if( $vars->{dom} ) {
                    @input =
                        $vars->{dom}->find($attr{cpath})->map('text')->each;
                }
            } elsif ($attr{xpath}) {
                # XML
                unless (exists $vars->{xml}) {
                    $vars->{xml} = Mojolicious::Plugin::Vparam::XML::parse_xml(
                        $self->req->body // ''
                    );
                }
                if( $vars->{xml} ) {
                    @input = map {$_->textContent}
                        $vars->{xml}->findnodes($attr{xpath});
                }
            } elsif ($type && $type eq 'object') {
                # PHP, jQuery, Ruby, etc.
                my @names = grep m{^$name\[}, @{$self->req->params->names};
                @input = ( { map { $_ => params($self, $_) } @names });
            } else {
                # POST parameters
                @input = params($self, $name);
            }

            # Set undefined value if parameter not set
            # if array or hash then keep it empty
            @input = (undef)
                if
                    not @input
                and not $attr{array}
                and not $attr{hash}
            ;

            # Set array if values more that one
            $attr{array} = 1 if @input > 1 and not $attr{hash};

            if( $attr{multiline} ) {
                if( $attr{array} ) {
                    die 'Array of arrays not supported';
                } else {
                    my $regexp = 'Regexp' eq ref $attr{multiline}
                         ? $attr{multiline}
                         : qr{\r?\n}
                    ;
                    # Apply multiline
                    @input =
                        grep { $_ =~ m{\S} }
                        map  { split $regexp, $_ } @input;
                }

                # Multiline force array
                $attr{array} = 1;
            }

            # Normalize hash key delimiter
            $attr{hash} = $conf->{hash_delimiter}
                if $attr{hash} && $attr{hash} eq '1';

            # Process on all input values
            my @keys;
            my @output;
            for my $index ( 0 .. $#input ) {
                my $in = my $out = $input[$index];
                my $key;

                if( $attr{hash} ) {
                    my @splitted = split $attr{hash}, $out, 2;
                    unless( @splitted == 2 ) {
                        $self->verror(
                            $name,
                            %attr,
                            index   => $index,
                            in      => $in,
                            out     => $out,
                            message => 'Not a hash',
                        );
                        next;
                    }

                    $key = $splitted[0];
                    $in = $out = $splitted[1];
                }

                # Apply pre filter
                $out = $attr{pre}->( $self, $out, \%attr )   if $attr{pre};

                # Apply validator
                if( $attr{valid} ) {
                    if( my $error = $attr{valid}->($self, $out, \%attr) ) {
                        # Set default value if error
                        $out = $attr{default};

                        # Default value always supress error
                        $error = 0 if exists $attr{default};

                        # Disable error on optional
                        if( $attr{optional} ) {
                            # Only if input param not set
                            $error = 0 if not defined $in;
                            $error = 0 if defined($in) and $in =~ m{^\s*$};
                        }

                        $self->verror(
                            $name,
                            %attr,
                            index   => $index,
                            in      => $in,
                            out     => $out,
                            message => $error,
                        ) if $error;
                    }
                }

                # Hack for bool values:
                # HTML forms do not transmit if checkbox off
                if( $type and not defined $in ) {
                    if( $type eq 'bool' ) {
                        $out = exists $attr{default}
                            ? $attr{default}
                            : 0
                        ;
                    }
                    if( $type eq 'logic' ) {
                        $out = $attr{default};
                    }
                }

                # Apply post filter
                $out = $attr{post}->( $self, $out, \%attr )  if $attr{post};

                # Apply other filters
                for my $key ( keys %attr ) {
                    # Skip unknown attribute
                    next unless $conf->{filters}{ $key };

                    my $error = $conf->{filters}{ $key }->(
                        $self, $out, $attr{ $key }
                    );
                    if( $error ) {
                        # Set default value if error
                        $out = $attr{default};

                        # Default value always supress error
                        $error = 0 if defined $attr{default};
                        # Disable error on optional
                        if( $attr{optional} ) {
                            # Only if input param not set
                            $error = 0 if not defined $in;
                            $error = 0 if defined($in) and $in =~ m{^\s*$};
                        }

                        $self->verror(
                            $name,
                            %attr,
                            index   => $index,
                            in      => $in,
                            out     => $out,
                            message => $error,
                        ) if $error;
                    }
                }

                # Add output
                if( defined($out) or not $attr{skipundef} ) {
                    push @output,   $out;
                    push @keys,     $key if $attr{hash} and defined $key;
                }
            }

            # Error for required empty array
            $self->verror( $name, %attr, message => 'Empty array' )
                if $attr{array} and not $attr{optional} and not @input;
            # Error for required empty hash
            $self->verror( $name, %attr, message => 'Empty hash' )
                if $attr{hash} and not $attr{optional} and not @input;

            # Rename for model
            my $as = $attr{as} // $name;

            if( $attr{hash} ) {
                $result{ $as } = { mesh @keys, @output };
            } elsif( $attr{array} ) {
                if( defined $attr{multijoin} ) {
                    $result{ $as } = @output
                        ? join $attr{multijoin}, grep {defined} @output
                        : undef
                    ;
                } else {
                    $result{ $as } = \@output;
                }
            } else {
                $result{ $as } = $output[0]
                    unless $attr{skipundef} and not defined($output[0]);
            }
            # Mojolicious::Validator::Validation
            $self->validation->output->{$name} = $result{ $as }
                if $conf->{mojo_validator};
        }

        return wantarray ? %result : \%result;
    });

    # One parameter
    $app->helper(vparam => sub{
        my ($self, $name, $def, %attr) = @_;

        die 'Parameter name required'               unless defined $name;
        die 'Parameter type or definition required' unless defined $def;

        my $result;

        unless( %attr ) {
            $result = $self->vparams( $name => $def );
        } elsif( 'HASH' eq ref $def ) {
            # Ignore attrs not in HashRef
            $result = $self->vparams( $name => $def );
        } elsif( 'Regexp' eq ref $def ) {
            $result = $self->vparams( $name => { regexp => $def, %attr } );
        } elsif('CODE' eq ref $def) {
            $result = $self->vparams( $name => { post   => $def, %attr } );
        } elsif('ARRAY' eq ref $def) {
            $result = $self->vparams( $name => { in     => $def, %attr } );
        } else {
            $result = $self->vparams( $name => { type   => $def, %attr } );
        }

        return $result->{ $attr{as} // $name };
    });

    # Load extensions: types, filters etc.
    for my $module (find_modules 'Mojolicious::Plugin::Vparam') {
        my $e = load_class( $module );
        die $e if $e;

        next unless $module->can('register');
        $module->register($self, $app, $conf);
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Vparam - Mojolicious plugin validator for GET/POST data.

=head1 DESCRIPTION

Features:

=over

=item *

Simple syntax or full featured

=item *

Many predefined types

=item *

Shortcuts for the most common uses

=item *

Filters complementary types

=item *

Support arrays and hashes of values

=item *

Support HTML checkbox as bool

=item *

Simple JSON values extraction and validation using JSON Pointer from
L<Mojo::JSON::Pointer>.

=item *

Simple XML/HTML values extraction and validation using CSS selector engine
from L<Mojo::DOM::CSS> or XPath from L<XML::LibXML>.

=item *

Support objects via parameters

=item *

Validate all parameters at once and get hash to simple use in any Model

=item *

Manage validation errors

=item *

Full Mojolicious::Validator::Validation integration

=back

This module use simple parameters types B<str>, B<int>, B<email>, B<bool>,
etc. to validate.
Instead of many other modules you mostly not need add specific validation
subs or rules.
Just set parameter type. But if you want sub or regexp you can do it too.

=head1 SYNOPSIS

    # Add plugin in startup
    $self->plugin('Vparam');

    # Use in controller
    $login      = $self->vparam(login    => 'str');
    $passw      = $self->vparam(password => 'password', size     => [8, 100]);
    $email      = $self->vparam(email    => 'email',    optional => 1);
    $session    = $self->vparam(session  => 'bool',     default  => 1);

    $ids        = $self->vparam(ids => '@int');

=head1 METHODS

=head2 vparam

Get one parameter. By default parameter is required.

    # Simple get one parameter
    $param1 = $self->vparam(date => 'datetime');

    # Or more syntax
    $param2 = $self->vparam(count => {type => 'int', default => 1});
    # Or more simple syntax
    $param2 = $self->vparam(count => 'int', default => 1);

=head2 vparams

Get many parameters as hash. By default all parameters are required.

    %params = $self->vparams(
        # Simple syntax
        name        => 'str',
        password    => qr{^\w{8,32}$},
        myparam     => sub { $_[1] && $_[1] eq 'ok' ? 1 : 0 } },
        someone     => ['one', 'two', 'tree'],

        # More syntax
        from        => { type   => 'date', default => '' },
        to          => { type   => 'date', default => '' },
        id          => { type   => 'int' },
        money       => { regexp => qr{^\d+(?:\.\d{2})?$} },
        myparam     => { post   => sub { $_[1] && $_[1] eq 'ok' ? 1 : 0 } },

        # Checkbox
        isa         => { type => 'bool', default => 0 },
    );

=head2 vsort

Like I<vparams> but add some keys to simple use with tables. Example:

    # HTML - table with controls and filters
    Order by:
    <select name="oby">
        <option value="0">Name</option>
        <option value="1">Date</option>
    </select>
    Order direction:
    <select name="ods">
        <option value="asc">Low to High</option>
        <option value="desc">High to Low</option>
    </select>
    Count per page:
    <select name="rws">
        <option value="10">10</option>
        <option value="100">100</option>
    </select>
    Filter by name:
    <input type="text" name="name" value="">
    Any other filters ...


    # Controller
    %params = $self->vsort(
        -sort       => ['name', 'date', ...],

        # next as vparams
        name        => 'text',
        ...
    );

=over

=item page

Page number. Default: 1.

You can set different name by I<vsort_page> config parameter.
If you set undef then parameter is not apply.

=item rws

Rows on page. Default: 25.

You can set different name by I<vsort_rws> config parameter.
You can set different default by I<vsort_rows> config parameter.
If you set undef then parameter is not apply.

=item oby

Column number for sorting. Default: 1 - in many cases first database
column is primary key.

You can set different name by I<vsort_oby> config parameter.
If you set undef then parameter is not apply.

Value of B<oby> The value will be automatically mapped to the column name
using the L</-sort> attribute.
Also, the value will be checked for proper mapping.
So you do not need to worry about it.

=item ods

Sort order ASC|DESC. Default: ASC.

You can set different name by I<vsort_ods> config parameter.
If you set undef then parameter is not apply.

=back

=head2 verror $name

Get parameter error string. Return 0 if no error.

    # Get error
    print $self->verror('myparam');

    # Get error for first element in array
    print $self->verror('myparam' => 0);

    # Set error
    $self->verror('myparam', message => 'Error message')

=head2 verrors

Return errors count in scalar context. In list context return errors hash.

    # List context get hash
    my %errors = $self->verrors;

    # Scalar context get count
    die 'Errors!' if $self->verrors;

=head2 vclass $name, @classes

Get classes for invalid input. Return empty string if no error.

    # Form example
    <input name="myparam" class="<%= vclass 'myparam' %>">
    # Return next code for invalid I<myparam>:
    # <input name="myparam" class="field-with-error">

You can set additional I<@classes> to set if field invalid.

=head2 vvalue $name, $default

Get raw input value after validation. Return I<$default> value or empty
string before validation.

    # Form example:
    <input name="myparam" value="<%= vvalue 'myparam' %>">

    # Return next code if user just open form without submit and validation:
    # <input name="myparam" value="">

    # Then user submit form and you validate id. For example user submit "abc":
    # <input name="myparam" value="abc">

=head2 vtype $name, %opts

Set new type $name if defined %opts. Else return type $name definition.

    # Get type
    $self->vtype('mytype');

    # Set type
    # load  - requires modules
    # pre   - get int
    # valid - check for not empty
    # post  - force number
    $self->vtype('mytype',
        pre     => sub {
            my ($self, $param) = @_;
            return int $param // '';
        },
        valid   => sub {
            my ($self, $param) = @_;
            return length $param ? 0 : 'Invalid'
        },
        post    => sub {
            my ($self, $param) = @_;
            return 0 + $param;
        }
    );

=head2 vfilter $name, &sub

Set new filter $name if defined %opts. Else return filter $name definition.

    # Get filter
    $self->vfilter('myfilter');

    # Set filter
    $self->vfilter('myfilter', sub {
        my ($self, $param, $expression) = @_;
        return $param eq $expression ? 0 : 'Invalid';
    });

Filter sub must return 0 if parameter value is valid. Or error string if not.

=head1 SIMPLE SYNTAX

You can use the simplified syntax instead of specifying the type,
simply by using an expression instead.

=over

=item I<REGEXP>

Apply as L</regexp> filter. No type verification, just match.

    $self->vparam(myparam => qr{^(abc|cde)$});

=item I<CODE> $mojo, $value

Apply as L</post> function. You need manual verify and set error.

    $self->vparam(myparam => sub { $_[1] && $_[1] eq 'good' ? 1 : 0 });

=item I<ARRAY>

Apply as L</in> filter. No type verification, just match.

    $self->vparam(myparam => [qw(abc cde)]);

=back

=head1 CONFIGURATION

=over

=item class

CSS class for invalid parameters. Default: field-with-error.

=item types

You can simple add you own types.
Just set this parameters as HashRef with new types definition.

=item filters

You can simple add you own filters.
Just set this parameters as HashRef with new filters definition.


=item vsort_page

Parameter name for current page number in I<vsort>. Default: page.

=item vsort_rws

Parameter name for current page rows count in I<vsort>. Default: rws.

=item rows

Default rows count for I<vsort_rws>. Default: 25.

=item vsort_oby

Parameter name for current order by I<vsort>. Default: oby.

=item vsort_ods

Parameter name for current order destination I<vsort>. Default: ods.

=item ods

Default order destination for I<vsort_rws>. Default: ASC.

=item phone_country

Phone country. Default: empty.

=item phone_region

Phone region. Default: empty.

=item phone_fix

Name of algorithm to fix phone, typicallty country code. Default: empty.

=item date

Date format for strftime. Default: %F.
if no format specified, return L<DateTime> object.

=item time

Time format for strftime. Default: %T.
if no format specified, return L<DateTime> object.

=item datetime

Datetime format for strftime. Default: '%F %T %z'.
if no format specified, return L<DateTime> object.

=item blessed

By default return objects used for parse or validation:
L<Mojo::URL>, L<DateTime>, etc.

=item optional

By default all parameters are required. You can change this by set this
parameter as true.

=item address_secret

Secret for address:points signing. Format: "ADDRESS:LATITUDE,LONGITUDE[MD5]".
MD5 ensures that the coordinates belong to address.

=item password_min

Minimum password length. Default: 8.

=item hash_delimiter

Delimiter to split input parameter on two parts: key and value.
Default: => - like a perl hash.

=item mojo_validator

Enable L<Mojolicious::Validator::Validation> integration.

=back

=cut

=head1 TYPES

List of supported types:

=head2 int

Signed integer. Use L</min> filter for unsigned.

=head2 numeric or number

Signed number. Use L</min> filter for unsigned.

=head2 money

Get money. Use L</min> filter for unsigned.

=head2 percent

Unsigned number: 0 <= percent <= 100.


=head2 str

Trimmed text. Must be non empty if required.

=head2 text

Any text. No errors.

=head2 password

String with minimum length from I<password_min>.
Must content characters and digits.

=head2 uuid

Standart 32 length UUID. Return in lower case.

=head2 date

Get date. Parsed from many formats.
See I<date> configuration parameter for result format.
See L<DateTime::Format::DateParse> and even more.

=head2 time

Get time. Parsed from many formats.
See I<time> configuration parameter for result format.
See L<DateTime::Format::DateParse> and even more.

=head2 datetime

Get full date and time. Parsed from many formats.
See I<datetime> configuration parameter for result format.

Input formats:

=over

=item *

Timestamp.

=item *

Relative from now in format C<[+-] DD HH:MM:SS>. First sign required.

=over

=item *

Minutes by default. Example: C<+15> or C<-6>.

=item *

Minutes and seconds. Example: C<+15:44>.

=item *

Hours. Example: C<+3:15:44>.

=item *

Days. Example: C<+8 3:15:44>.

=back

Values are given in arbitrary range.
For example you can add 400 minutes and 300 seconds: C<+400:300>.

=item *

All that can be obtained L<DateTime::Format::DateParse>.

=item *

Russian date format like C<DD.MM.YYYY>

=back

=head2 bool

Boolean value. Can be used to get value from checkbox or another sources.

HTML forms do not send checbox if it checked off. So you don`t get error,
but get false for it.

    $self->vparam(mybox => 'bool');

Valid values are:

=over

=item

I<TRUE> can be 1, yes, true, ok

=item

I<FALSE> can be 0, no, false, fail

=item

Empty string is I<FALSE>

=back

Other values get error.

Example:

    <input type="checkbox" name="bool1" value="yes">
    <input type="checkbox" name="bool2" value="1">
    <input type="checkbox" name="bool3" value="ok">

=head2 logic

Three-valued logic. Same as I<bool> but undef state if empty string. Example:

    <select name="logic1">
        <option value=""></option>
        <option value="1">True</option>
        <option value="0">False</option>
    </select>

=head2 email

Email adress.

=head2 url

Get url as L<Mojo::URL> object.

=head2 phone

Phone in international format. Support B<wait>, B<pause> and B<additional>.

You can set default country I<phone_country> and region I<phone_country> codes.
Then you users can input shortest number.
But this is not work if you site has i18n.

=head2 json

JSON incapsulated as form parameter.

=head2 address

Location address. Two forms are parsed: string and json.
Can verify adress sign to trust source.

=head2 lon

Longitude.

=head2 lat

Latilude.

=head2 isin

International Securities Identification Number:
Mir, American Express, Diners Club, JCB, Visa,
MasterCard, Maestro, etc.

You can check for ISIN type like:

    # Mir
    $self->vparam(card => 'isin', regexp => qr{^2});

    # American Express, Diners Club, JCB
    $self->vparam(card => 'isin', regexp => qr{^3});

    # Visa
    $self->vparam(card => 'isin', regexp => qr{^4});

    # MasterCard
    $self->vparam(card => 'isin', regexp => qr{^5});

    # Maestro
    $self->vparam(card => 'isin', regexp => qr{^6});

=head2 maestro

Some local country, not 16 numbers cards: Maestro, Visa Electron, etc.

=head3 creditcard

Aggregate any creditcard: ISIN, Maestro, etc.

=head2 barcode

Barcode: EAN-13, EAN-8, EAN 5, EAN 2, UPC-12, ITF-14, JAN, UPC, etc.

    $self->vparam(barcode => 'goods');

=head2 inn

RU: Taxpayer Identification Number

=head2 kpp

RU: Code of reason for registration

=head2 object

Simple objects via parameters (without validation!). Example:

# {foo => [ {bar => 1, baz => 2} ]}
?param1[foo][0][bar]=1&param1[foo][0][baz]=2

This is experimental feature. We think how to validate parameters.

=head1 ATTRIBUTES

You can set a simple mode as in example or full mode. Full mode keys:


=head2 default

Default value. Default: undef.

    # Supress myparam to be undefined and error
    $self->vparam(myparam => 'str', default => '');

=head2 load

Autoload module for this type.
Can be module name, array of module names or sub.

=head2 pre $mojo, &sub

Incoming filter sub. Used for primary filtration: string length and trim, etc.
Result will be used as new param value.

Usually, if you need this attribute, you need to create a new type.

=head2 valid $mojo, &sub

Validation sub. Return 0 if valid, else string of error.

Usually, if you need this attribute, you need to create a new type.

=head2 post $mojo, &sub

Out filter sub. Used to modify value for use in you program. Usually used to
bless in some object.
Result will be used as new param value.

=head2 type

Parameter type. If set then some filters will be apply. See L</TYPES>.

    $self->vparam(myparam => 'datetime');
    $self->vparam(myparam => {type => 'datetime'});
    $self->vparams(
        myparam1 => {type => 'datetime'},
        myparam2 => {isa  => 'datetime'},
    );

After the application of the type used filters.

You can use B<isa> alias instead of B<type>.

=head2 as

Rename output key for I<vparams> to simple use in models.

    # Return {login => '...', password => '...'}
    $self->vparams(
        myparam1 => {type => 'str', as => 'login'},
        myparam2 => {type => 'str', as => 'password'},
    );

=head2 array

Force value will array. Default: false.

You can force values will arrays by B<@> prefix or case insensive B<array[...]>.

    # Arrays shortcut syntax
    $param1 = $self->vparam(array1 => '@int');
    $param2 = $self->vparam(array2 => 'array[int]');

    # Array attribute syntax
    $param3 = $self->vparam(array3 => 'int', array => 1);

    # The array will come if more than one value incoming
    # Example: http://mysite.us?array4=123&array4=456...
    $param4 = $self->vparam(array4 => 'int');

=head2 hash

Get value as hash. Default: false.
You can get values as hash by B<%> prefix.

To make hash vparam split value by predefined delimiter
(see I<hash_delimiter> configuration parameter). It`s important to make
value format.

    # Get param1 as hash. Parameter value need to be like 'a=>1'.
    $param1 = $self->vparam(myparam1 => '%int');

    # Same, but custom delimiter "::"
    $param2 = $self->vparam(myparam2 => 'int', hash => '::');

    # Multiple parameters supported.
    # You can send many myparam3 with different values list like:
    # ?myparam3=a_1&myparam3=b_2&myparam3=c_3
    # and get perl hash like $param3 = {a => 1, b => 3, c => 3}
    $param3 = $self->vparam(myparam3 => '%int', hash => '_');

=head2 optional

By default all parameters are required. You can change this for parameter by
set I<optional>.
Then true and value is not passed validation don`t set verrors.

    # Simple vparam
    # myparam is undef but no error.
    $param1 = $self->vparam(param1 => 'int', optional => 1);

    # Set one in vparams
    %params = $self->vparams(
        myparam     => { type => 'int', optional => 1 },
    );

    # Set all in vparams
    %params = $self->vparams(
        -optional   => 1,
        param1      => 'int',
        param2      => 'str',
    );

    # Shortcut optional syntax
    $param2 = $self->vparam(param2 => '?int');
    $param3 = $self->vparam(param3 => 'maybe[int]');
    $param4 = $self->vparam(param4 => 'optional[int]');

    # Shortcut required syntax
    $param5 = $self->vparam(param5 => '!int');
    $param6 = $self->vparam(param6 => 'require[int]');
    $param7 = $self->vparam(param7 => 'required[int]');

=head2 skip

So as not to smear the validation code you can use the I<skip> parameter
to skip on the condition.
This attribute is useful for controlling access to the form fields.

    # This example don`t get param1 in production mode.

    # HTML
    % unless( $self->app->mode eq 'production' ) {
        %= number_field 'param1'
    % }

    # Simple flag
    $param1 = $self->vparam(
        param1      => 'int', skip => $self->app->mode eq 'production',
    );

    # Same as by use sub.
    $param1 = $self->vparam(
        param1      => 'int', skip => sub { $_[0]->app->mode eq 'production' },
    );

If you use sub then first parameter is controller.

=head2 skipundef

By default all parameters are in output hash. You can skip parameter in result
if it`s undefined by set I<skipundef>.

    # Simple vparam
    # myparam is undef.
    $param1 = $self->vparam(param1 => 'int', optional => 1, skipundef => 1);

    # Simple flag
    # The %params hash is empty if myparam value is not integer.
    %params = $self->vparams(
        myparam     => { type => 'int', optional => 1, skipundef => 1 },
    );

    # Set all in vparams
    # The %params hash is empty if all parameters are not valid.
    %params = $self->vparams(
        -skipundef  => 1,
        param1      => 'int',
        param2      => 'str',
    );

    # Shortcut syntax: skipundef and optional is on
    $param2 = $self->vparam(param2 => '~int');

Arrays always return as arrayref. But undefined values will be skipped:

    # This vparam return [1,2,3] for ?param3=1&param3=&param3=2&param3=3
    $param2 = $self->vparam(param3 => '~int');

=head2 multiline

You can simple split I<textarea> to values:

    # This vparam return [1,2,3] for input "1\n2\n3\n"
    $param1 = $self->vparam(param1 => 'int', multiline => 1);

    # Or by custom regexp
    # This vparam return [1,2,3] for input "1,2,3"
    $param1 = $self->vparam(param1 => 'int', multiline => qr{\s*,\s*});

Empty lines ignored.

=head2 multijoin

Any array values can be joined in string:

    # This vparam return "1,2,3" for input ?param1=1&param1=2&param1=3
    $param1 = $self->vparam(param1 => 'int', multijoin => ',');

    # This vparam return "1,2,3" for input "1\n2\n3\n"
    $param2 = $self->vparam(param2 => 'int', multiline => 1, multijoin => ',');

=head2 blessed

Keep and return blessed object for parsed parameters if available.
Vparam always return scalars if disabled.

Note: if defined I<date>, I<time>, I<datetime> then always return
formatted scalar.

=head2 jpath or jpath?

If you POST data not form but raw JSON you can use JSON Pointer selectors
from L<Mojo::JSON::Pointer> to get and validate parameters.

    # POST data contains:
    # {"point":{"address":"some", "lon": 45.123456, "lat": 38.23452}}

    %opts = $self->vparams(
        address => { type => 'str', jpath => '/point/address' },
        lon     => { type => 'lon', jpath => '/point/lon' },
        lat     => { type => 'lat', jpath => '/point/lat' },
    );

Note: we don`t support multikey in json. Use hash or die.

If You use C<jpath?> instead C<jpath>, vparam tries parse input json, if
json is invalid vparam tries fetch param from input form:


    ######################## works:
    # {"point":{"address":"some", "lon": 45.123456, "lat": 38.23452}}

    # #######################works:
    # address=some&lon=45.123456&lat=38.23452

    ################# doesn't work:
    # query: address=some
    # body:  {"point":{"lon": 45.123456, "lat": 38.23452}}

    %opts = $self->vparams(
        address => { type => 'str', 'jpath?' => '/point/address' },
        lon     => { type => 'lon', 'jpath?' => '/point/lon' },
        lat     => { type => 'lat', 'jpath?' => '/point/lat' },
    );

Note: You cant mix C<jpath> and C<jpath?>: If body contains valid JSON, vparam
doesn't try check form params.


=head2 cpath

Same as jpath but parse XML/HTML using CSS selectors from L<Mojo::DOM::CSS>.

    # POST data contains:
    # <Point>
    #    <Address>some</Address>
    #    <Lon>45.123456</Lon>
    #    <Lat>38.23452</Lat>
    # </Point>

    %opts = $self->vparams(
        address => { type => 'str', cpath => 'Point > Address' },
        lon     => { type => 'lon', cpath => 'Point > Lon' },
        lat     => { type => 'lat', cpath => 'Point > Lat' },
    );


=head2 xpath

Same as cpath but parse XML/HTML using XPath selectors from L<XML::LibXML>.

    # POST data contains:
    # <Point time="2016-11-25 14:39:00 +0300">
    #    <Address>some</Address>
    #    <Lon>45.123456</Lon>
    #    <Lat>38.23452</Lat>
    # </Point>

    %opts = $self->vparams(
        address => { type => 'str',         xpath => '/Point/Address' },
        lon     => { type => 'lon',         xpath => '/Point/Lon' },
        lat     => { type => 'lat',         xpath => '/Point/Lat' },
        time    => { type => 'datetime',    xpath => '/Point/@time' },
    );

=head1 RESERVED ATTRIBUTES

=head2 -sort

List of column names for I<vsort>. Usually not all columns visible for users and
you need convert column numbers in names. This also protect you SQL queries
from set too much or too low column number.

=head2 -optional

Set default I<optional> flag for all params in L</vparams> and L</vsort>.

=head2 -skipundef

Set default I<skipundef> flag for all params in L</vparams> and L</vsort>.

=head1 FILTERS

Filters are used in conjunction with types for additional verification.

=head2 range

Check parameter value to be in range.

    # Error if myparam less than 10 or greater than 100
    $self->vparam(myparam => 'int', range => [10, 100]);

=head2 regexp

Check parameter to be match for regexp

    # Error if myparam not equal "abc" or "cde"
    $self->vparam(myparam => 'str', regexp => qr{^(abc|cde)$});

=head2 in

Check parameter value to be in list of defined values.

    # Error if myparam not equal "abc" or "cde"
    $self->vparam(myparam => 'str', in => [qw(abc cde)]);

=head2 size

Check maximum length in utf8.

    # Error if value is an empty string
    $self->vparam(myparam => 'str', size => [1, 100]);

=head2 Numbers comparation

I<min>, I<max>, I<equal>, I<not>

=head2 Strings comparation

I<lt>, I<gt>, I<le>, I<ge>, I<cmp>, I<eq>, I<ne>

=head1 RESTRICTIONS

=over

=item *

Version 1.0 invert I<valid> behavior: now checker return 0 if no error
or description string if has.

=item *

New errors keys: orig => in, pre => out

=back

=head1 SEE ALSO

L<Mojolicious::Validator::Validation>, L<Mojolicious::Plugin::Human>.

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
