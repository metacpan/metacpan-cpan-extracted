package MooseX::Getopt::Defanged;

use 5.010;
use utf8;

use Moose::Role;
use Moose::Util::TypeConstraints;


# No :all so we don't depend upon IPC::System::Simple.
use autodie qw< :default >;
use English qw< $EVAL_ERROR -no_match_vars >;
use Readonly;

use version; our $VERSION = qv('v1.18.0');


use Getopt::Long qw<>;


use MooseX::Getopt::Defanged::Exception::Generic qw< throw_generic >;
use MooseX::Getopt::Defanged::Exception::User qw< throw_user >;
use MooseX::Getopt::Defanged::OptionTypeMetadata;


has remaining_argv => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 0,
    init_arg    => undef,   # Cannot be specified in constructor call.
    reader      => 'get_remaining_argv',
    writer      => '_set_remaining_argv',
    auto_deref  => 1,
);

has option_type_metadata => (
    is          => 'ro',
    isa         => 'MooseX::Getopt::Defanged::OptionTypeMetadata',
    required    => 1,
    default     => sub { MooseX::Getopt::Defanged::OptionTypeMetadata->new() },
    reader      => 'get_option_type_metadata',
);


sub parse_command_line {
    my ($self, $argv_ref) = @_;

    my $option_values_ref =
        $self->_getopt_invoke_getopt_long($argv_ref);

    $self->_getopt_assign_option_values($option_values_ref);

    return;
} # end parse_command_line()


sub _getopt_get_option_attributes {
    my ($self) = @_;

    my $metadata = $self->meta();
    my @option_attributes =
        grep {
            $_->does('MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt')
        }
        $metadata->get_all_attributes();

    return \@option_attributes;
} # end _getopt_get_option_attributes()


sub _getopt_invoke_getopt_long {
    my ($self, $argv_ref) = @_;

    my $stderr;

    my $parser = Getopt::Long::Parser->new(
        config => [
            # Unfortunately, bundling is incompatible with allowing multiple
            # values for a given option (why I don't know, but Getopt::Long
            # complains if gnu_getopt, and thus bundling, is turned on).
            qw<
                no_auto_abbrev
                no_auto_help
                no_auto_version
                no_bundling
                no_getopt_compat
                   gnu_compat
                no_ignore_case
                   permute
            >
        ],
    );

    my @option_attributes =
        @{ $self->_getopt_get_option_attributes() };
    my $type_metadata = $self->get_option_type_metadata();
    my %option_values =
        map { ## no critic (Lax::ProhibitComplexMappings::LinesNotStatements)
                $_->get_actual_option_name()
            =>  $_->get_stringified_value_or_default($self, $type_metadata)
        }
        grep {
            defined $_->get_stringified_value_or_default($self, $type_metadata)
        }
            @option_attributes;
    my @specification_strings =
        map { $_->get_full_specification($type_metadata) } @option_attributes;

    my $parse_worked;

    {
        local @ARGV = @{$argv_ref};

        open my $stderr_handle, '>', \$stderr;
        $parse_worked = _getopt_invoke_getopt_long_while_handling_exceptions(
            $parser, $stderr_handle, \%option_values, \@specification_strings,
        );
        close $stderr_handle;

        $self->_set_remaining_argv( [ @ARGV ] );
    } # end scoping block

    throw_user $stderr // 'Could not parse command-line.'
        if not $parse_worked;

    return \%option_values;
} # end _getopt_invoke_getopt_long()


# If an exception is unhandled while STDERR is localized, STDERR never gets
# un-localized, meaning that the error never gets emitted to the real STDERR.
# So we run Getopt::Long::Parser::getoptions() inside of an eval and rethrow
# any exception after STDERR is no longer localized.
sub _getopt_invoke_getopt_long_while_handling_exceptions {
    my ($parser, $stderr_handle, $option_values_ref, $specification_strings_ref)
        = @_;

    my $getopt_error;
    my $parse_worked;
    {
        local *STDERR = $stderr_handle;

        eval {
            $parse_worked =
                $parser->getoptions(
                    $option_values_ref, @{$specification_strings_ref},
                );
            1;
        }
            or do {
                $getopt_error =
                        $EVAL_ERROR
                    //  'Getopt::Long::Parser::getoptions() failed for an unknown reason.';
            };
    } # end scoping block

    if (defined $getopt_error) {
        throw_generic $getopt_error;
    } # end if

    return $parse_worked;
} # end _getopt_invoke_getopt_long_while_handling_exceptions()


sub _getopt_assign_option_values {
    my ($self, $option_values_ref) = @_;

    my $type_metadata = $self->get_option_type_metadata();

    my $error_message;
    foreach my $option_attribute (
        @{ $self->_getopt_get_option_attributes() }
    ) {
        my $option_name = $option_attribute->get_actual_option_name();
        if ( exists $option_values_ref->{$option_name} ) {
            $option_attribute->set_value_with_destringification(
                $option_values_ref->{$option_name}, $self, $type_metadata,
            );
        } elsif ( $option_attribute->is_getopt_required() ) {
            $error_message .=
                "The --$option_name argument must be specified.\n";
        } # end if
    } # end foreach

    if ($error_message) {
        throw_user $error_message;
    } # end if

    return;
} # end _getopt_get_option_attributes()


no Moose::Role;

1;

__END__

=encoding utf8

=for stopwords ArrayRef ArrayRefs foO olde stringification RegexpRef whitespace

=head1 NAME

MooseX::Getopt::Defanged - Standard processing of command-line options, with Getopt::Long's nasty behavior defanged.


=head1 SYNOPSIS

    package Some::Application


    use Moose;


    with qw< MooseX::Getopt::Defanged >;

    # Sets up a standard command-line option that takes a value named
    # 'some-option'.
    has some_option => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => 'Str',
    );

    # Any Moose attributes that don't have the
    # MooseX::Getopt::Defanged::Option trait are ignored.
    has some_plain_attribute => (
        is      => 'rw',
        isa     => 'Str',
    );

    # Change the name of the command-line option with "getopt_name".
    # So, instead of the user specifying "--different-named-option", they
    # would specify "--blah".
    has different_named_option => (
        traits      => [ qw< MooseX::Getopt::Defanged::Option > ],
        is          => 'rw',
        isa         => 'Str',
        getopt_name => 'blah',
    );

    # Add alternate names for the option that the user can use via
    # "getopt_aliases".  In this case, the user will be able to specify
    # "--option-with-aliases", "--aliases", or "-a".
    has option_with_aliases => (
        traits          => [ qw< MooseX::Getopt::Defanged::Option > ],
        is              => 'rw',
        isa             => 'Str',
        getopt_aliases  => [ qw< aliases a > ],
    );

    # Change which modifiers get applied when compiling the value of a regular
    # expression option.  The default modifiers are "m" and "s".
    has regex_option => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'RegexpRef',
        getopt_regex_modifiers  => [ qw< x m s > ],
    );

    # Make a regular expression option have no modifiers applied to it.
    has no_modifiers_regex_option => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'RegexpRef',
        getopt_regex_modifiers  => [ ],
    );

    # Forces the user to specify the "option" on the command-line.
    has argument => (
        traits          => [ qw< MooseX::Getopt::Defanged::Option > ],
        is              => 'rw',
        isa             => 'Str',
        getopt_required => 1,
    );

    # MooseX::Getopt::Defanged doesn't know how to handle your attribute type,
    # but there's a means of automatically coercing from types that
    # MooseX::Getopt::Defanged does know how to handle.  Tell it what it
    # should treat your attribute as by giving a value for "getopt_type".
    subtype 'MyDateTime' => as 'DateTime';

    coerce 'MyDateTime'
        => from 'Int'
        => via { DateTime->from_epoch(epoch => $_) };
    coerce 'MyDateTime'
        => from 'Str'
        => via { DateTime::Format::Natural->new()->parse_datetime($_) };

    has epoch_option => (
        traits      => [ qw< MooseX::Getopt::Defanged::Option > ],
        is          => 'rw',
        isa         => 'MyDateTime',
        getopt_type => 'Int',
    );

    has natural_time_option => (
        traits      => [ qw< MooseX::Getopt::Defanged::Option > ],
        is          => 'rw',
        isa         => 'MyDateTime',
        getopt_type => 'Str',
    );

    # Override the parsing part of the Getopt::Long specification with
    # "getopt_specification", in this instance to allow the user to specify
    # "--no-boolean-option".
    has boolean_option => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'Bool',
        getopt_specification    => q<!>,
    );

    # Provide a default value for the option using the standard Moose means
    # for defaults.
    has int_option => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => 'Int',
        default => 42,
    );

    # When the option is an object and a default value is given, one must
    # provide a way to stringify the object for Getopt::Long handling
    # using "getopt_stringifier".
    has natural_time_option => (
        traits              => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                  => 'rw',
        isa                 => 'MyDateTime',
        default             => sub {
            DateTime::Format::Natural->new()->parse_datetime('yesterday')
        },
        getopt_stringifier  => sub { scalar $_[0] },
        getopt_type         => 'Str',
    );

    # In addition to specifying the information on your option attributes, you
    # need to actually invoke the command-line handling.
    sub run_using_handle_for_output {
        my ($self, $handle, $argv_ref) = @_;

        $self->parse_command_line($argv_ref);

        ...
    } # end run_using_handle_for_output()


=head1 VERSION

This document describes MooseX::Getopt::Defanged version 1.18.0.


=head1 DESCRIPTION

This is a L<Moose::Role> for dealing with command-line options.  The core
implementation is ye olde L<Getopt::Long>, so it helps to understand this if
you read that documentation first.  Among other things, this role defeats
L<Getopt::Long>'s propensity for emitting stuff to C<STDERR> and for modifying
C<@ARGV>.

Since this is a role for L<Moose>, you use this by creating a class that uses
this one via C<with>.

Due to C<Getopt::Long> limitations with multiple-valued options, bundling of
single letter options is turned off.  In other words, if there are options
that can be specified as C<-x> and C<-y>, the user cannot use C<-xy> to
specify them both.


=head1 INTERFACE

Since this is a role, this isn't something instantiable, so there are no
constructors.


=head2 Attribute Options

Most of the time, you should be able to do nothing but use the C<traits>
option, and everything should "just work".  All of the other options are
actually optional.

=over

=item C<< traits => [ qw< MooseX::Getopt::Defanged::Option ... > ] >>

The C<traits> option is actually a standard one from L<Moose>.  It's how to
tell this role that the attribute describes a command-line option.

(If you need to trace the guts of the implementation of this role, note that
there is no MooseX::Getopt::Defanged::Option class/role.  Traits use the Moose
plug-in mechanism, so start your investigation by looking at
L<Moose::Meta::Attribute::Custom::Trait::MooseX::Getopt::Defanged::Option>.)


=item C<< getopt_name => 'name-on-the-command-line' >>

The C<getopt_name> option allows you to change what the option will be
referred to on the command-line.  By default, the option name will be the same
as the attribute name, with the underscores replaced by hyphens, e.g. an
attribute with the name "foo_bar" will become a "--foo-bar" option.

Note that an attribute with a name with a leading underscore (e.g. "_foo")
will normally be rejected by this role because such attributes are considered
to be private.  In order to improve the usefulness of your program, you should
allow your options to be driven by other Perl code.  However, if you really
want your attribute to be private, you can use this option to get around this
restriction.


=item C<< getopt_aliases => [ qw< alternate names > ] >>

If you want to allow the user to specify your option with other names than the
primary one, this option takes a reference to an array of strings.  This
translates to the L<Getopt::Long> "pipe|separated|alternatives" syntax.


=item C<< getopt_required => Bool >>

This turns the option into an argument, i.e. the user I<must> specify it on
the command line.  This applies even if there is a standard L<Moose>
C<default> or C<builder>.


=item C<< getopt_type => 'AMooseType' >>

If what you specify for the standard C<isa> option isn't what you want this
role to treat as the type of your attribute, you can override it with this
option.  However, be careful of your attribute type constraints and make sure
that there's a translation between the C<isa> and C<getopt_type> types.

Currently, this option is ignored if you specify a value for
C<getopt_specification>.


=item C<< getopt_specification => 'Getopt::Long format' >>

This allows you to completely override what this role will decide is the
format to use for the attribute/option.  This needs to be in the form of a
L<Getopt::Long> specification without the name and aliases part.  For example,
if you want to have an integer option with a required value that can be
specified in "extended" format, you would give "=o" as the value for this
option.  Similarly, if you want an incrementing integer option, you can
specify ":+".

You can find out the default types handled and their default specifications by
looking at L<MooseX::Getopt::Defanged::OptionTypeMetadata>.


=item C<< getopt_regex_modifiers => [ qw< some combination of "m", "s", "i", "x", "p" > ] >>

If the option is a C<RegexpRef> or a C<Maybe[RegexpRef]>, this allows you to
specify what modifiers will be applied when compiling the regular expression
specified on the command-line; see L<perlop/"Regexp Quote-Like Operators"> for
the significance of each.  This defaults to C<< [ qw< m s > ] >>.


=item C<< getopt_stringifier => CodeRef | Str >>

If the option is an object and a default value is given, one must translate
the object to a string representation prior to L<Getopt::Long> parsing.
Together with coercion, the option will get its object form after command line
arguments parsing. "getopt_stringifier" allows to you to specify how this
stringification is done.  The value can either be a code reference or a
string.  The function handling stringification will receive the option object
as the only argument.  It is expected to return the string value of the object
that can be later coerced back to a new instance of the object's class.  A
short-cut is provided if you specify a string as "getopt_stringifier" value.
It is then expected that the object contains method of this name which when
invoked will return the string representation of the object.

Rather than specifying this on individual options, you can handle an entire
type via
L<MooseX::Getopt::Defanged::OptionTypeMetadata/set_default_stringifier>.


=item C<< getopt_destringifier => CodeRef >>

If the option is an object and you don't have some form of coercion between a
string and the object type, you can say how to do the translation by
specifying this.  The value must be a code reference that takes a string as
its only argument and returns an object.  Generally, you want to use
L<MooseX::Getopt::Defanged::OptionTypeMetadata/set_default_destringifier>, but
this allows you to handle the translation on an individual option.


=back


=head2 Methods

=head3 C<parse_command_line($argv_ref)>

Parses the command-line indicated by the parameter, which is expected to be a
reference to an array of strings.  Returns nothing.

Throws a L<MooseX::Getopt::Defanged::Exception::Generic> if L<Getopt::Long>
complains about its parameters, e.g. if you give a bad option specification.
Throws a L<MooseX::Getopt::Defanged::Exception::User> if the user passes a bad
option on the command-line.


=head3 C<get_remaining_argv()>

After C<parse_command_line()> is called, this method will get you what remains
of C<@ARGV> as a list.


=head3 C<get_option_type_metadata()>

Returns the instance of L<MooseX::Getopt::Defanged::OptionTypeMetadata> used
to figure out defaults.  You can use this to change how all options of a given
type are handled.


=head1 ADDITIONAL EXAMPLES

For full details on how specifications work, refer to the L<Getopt::Long>
documentation.  But here are some examples of what a resulting command line
would look like, given a set of option attributes.


=over

=item Simple boolean.

An attribute like

    has boolean_option => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => 'Bool',
    );

Will result in a command-line like

    myprogram --boolean-option

where the user would specify the option if they wanted to turn it on and
simply not specify the option if they wanted it off.


=item Boolean that defaults to true, but can be turned off by the user.

    has boolean_option => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'Bool',
        default                 => 1,
        getopt_specification    => q<!>,
    );

The user could then say

    myprogram --no-boolean-option

to turn it off or say

    myprogram --boolean-option

to explicitly state the default (or be robust in the face of you changing the
default).


=item Integer with optional value.

The default specification for integers is C<=i>, which means that the user
must specify a value, i.e. if you have an attribute like

    has int_option => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => 'Int',
    );

then the user has to use the option like this

    myprogram --int-option 42

and

    myprogram --int-option

will result in an error.

If you want the latter case to actually work, you can change the specification
like so:

    has int_option => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'Int',
        getopt_specification    => ':i',
    );

In this scenario, if the user specifies the option without giving the value,
the attribute will be set to C<0>.  If the user doesn't specify the option,
the attribute will be undefined.


=item A RegexpRef which allows whitespace and ignores case.

An attribute given as

    has regex_option => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'RegexpRef',
        getopt_regex_modifiers  => [ qw< x m s i > ],
    );

will allow the user to say

    myprogram --regex-option '\A foo \z'

to match "foo", "foO", and "FOO".



=item ArrayRef which requires precisely two values.

The default specification for ArrayRefs is C<=«type»{1,}>, which means that
the user must specify at least one value, but can specify more.  E.g. the
default specification for "ArrayRef[Num]" is C<=f{1,}>.  So

    has some_numbers => (
        traits  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is      => 'rw',
        isa     => 'ArrayRef[Num]',
    );

would mean that if the user specified

    myprogram --some-numbers 2 1.3 0.61

then C<some_numbers> would contain C<[2, 1.3, 0.61]> and specifying the option
without any values would be an error.

Now if you want the user to be required to specify two and only two options,
you would change your attribute declaration to look like

    has some_numbers => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'ArrayRef[Num]',
        getopt_specification    => '=f{2}',
    );


=item ArrayRef with each value specified separately.

As you can see from the above example, the defaults for ArrayRefs are set so
that the user doesn't need to repeat the option for each value.  If you prefer
that each value be separately specified, change the attribute declaration to
look like this:

    has some_numbers => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'ArrayRef[Num]',
        getopt_specification    => '=f@',
    );

The user would then need to use the option like

    myprogram --some-numbers 2 --some-numbers 1.3 --some-numbers 0.61


=item Object with default value.

In order to support objects as options with a default value, you need to
define coercion from string and stringification of the object like this:

    subtype 'My::Types::File'
        => as class_type('Path::Class::File');
    coerce 'My::Types::File'
        => from 'Str'
            => via { Path::Class::File->new($_) };

    has file => (
        traits                  => [ qw< MooseX::Getopt::Defanged::Option > ],
        is                      => 'rw',
        isa                     => 'My::Types::File',
        coerce                  => 1,
        # This is coerced to a Path::Class::File object just like the value
        # given at the command line, if any
        default                 => '/path/to/file',
        getopt_type             => 'Str',
        # Stringify using Path::Class::File->stringify() method
        getopt_stringifier      => 'stringify',
        # or the same thing using a code reference.
        # getopt_stringifier    => sub { shift->stringify() },
    );

If the program was run like

    myprogram --file /some/file

the program code could then use

    sub some_method {
        my $self = shift;

        ref $self->file();          # Path::Class::File
        $self->file()->stringify(); # '/some/file'
        ...
    }

=back


=head1 DIAGNOSTICS

If you specify an attribute type that this class doesn't understand, a
L<MooseX::Getopt::Defanged::Exception::InvalidSpecification> will be thrown
with the message C<There's no "$type_name" type.>.

If the user specifies an invalid option, an instance of
L<MooseX::Getopt::Defanged::Exception::User> will be thrown with the message
from L<Getopt::Long>, or C<Could not parse command-line.> if L<Getopt::Long>
doesn't provide one.  Similarly, if the user doesn't specify an argument as
indicated by C<getopt_required>, an exception will be thrown with the message
C<The --I<whatever> argument must be specified.>.

If an invalid L<Getopt::Long> specification is found or it otherwise complains
about something programmer specified, an instance of
L<MooseX::Getopt::Defanged::Exception::Generic> is thrown with
L<Getopt::Long>'s message.


=head1 CONFIGURATION AND ENVIRONMENT

No external configuration is used.  The "configuration" is done in your class
on your attributes.  See above.


=head1 DEPENDENCIES

perl 5.10

L<autodie>

L<Exception::Class>

L<Getopt::Long>

L<Moose>

L<Moose::Role>

L<Moose::Util::TypeConstraints>

L<MooseX::Accessors::ReadWritePrivate>

L<MooseX::AttributeHelpers>

L<MooseX::StrictConstructor>

L<Readonly>

L<Scalar::Util>


=head1 COMPARISONS

Differences with L<MooseX::Getopt>:

=over

=item Causing parsing to happen.

L<MooseX::Getopt> has you invoke a C<new_with_options()> constructor.  This
module requires you to separately construct an object instance and then invoke
C<parse_command_line()>.


=item Picking which attributes result in command line options.

L<MooseX::Getopt> makes all attributes command-line options by default and
requires you to add a trait to the attributes that you don't want options for.
This module does the opposite: you have to add a trait to attributes that you
want command-line options for.

If you want the other L<MooseX::Getopt> behavior but want to explicitly state
which attributes turn into options, use L<MooseX::Getopt::Strict>.


=item Option parsing module used.

L<MooseX::Getopt> will use L<Getopt::Long::Descriptive>, if it is available.
This module only uses L<Getopt::Long>.


=item C<@ARGV>

After parsing with L<MooseX::Getopt>, C<@ARGV> will have parsed options
removed; a copy of it as it existed via prior to parsing is available via
the C<ARGV()> accessor.  After parsing with this role, C<@ARGV> is unchanged;
the stripped-down command-line arguments are available via
C<get_remaining_argv()>.


=item Bad user input handling.

If the user specifies invalid options on the command-line, problems detected
by L<MooseX::Getopt> (actually L<Getopt::Long>) will be emitted to C<STDERR>.
From this module, there is no output for bad user input; you will need to emit
errors yourself.  You can get at any error description via the message for the
L<MooseX::Getopt::Defanged::Exception::User> that will be thrown in this
circumstance.


=item Configuration file merging.

This module has no support for merging configuration file contents with
command-line options, but L<MooseX::Getopt> does.


=back


=head1 THE NAME

The author of this module does not like L<Getopt::Long>'s propensity for
modifying C<@ARGV> and writing directly to C<STDERR>, so this role defangs it.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2008-2010, Elliot Shank


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
