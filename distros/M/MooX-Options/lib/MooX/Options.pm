package MooX::Options;

use strictures 2;

our $VERSION = "4.103";

use Carp ('croak');
use Module::Runtime qw(use_module);

my @OPTIONS_ATTRIBUTES
    = qw/format short repeatable negatable autosplit autorange doc long_doc order json hidden spacer_before spacer_after/;

sub import {
    my ( undef, @import ) = @_;
    my $options_config = {
        protect_argv              => 1,
        flavour                   => [],
        skip_options              => [],
        prefer_commandline        => 0,
        with_config_from_file     => 0,
        with_locale_textdomain_oo => 0,
        usage_string              => undef,

        #long description (manual)
        description => undef,
        authors     => [],
        synopsis    => undef,
        spacer      => " ",
        @import
    };

    my $target = caller;
    for my $needed_methods (qw/with around has/) {
        next if $target->can($needed_methods);
        croak(    "Can't find the method <$needed_methods> in <$target>!\n"
                . "Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options."
        );
    }

    my $with   = $target->can('with');
    my $around = $target->can('around');
    my $has    = $target->can('has');

    my @target_isa;
    { no strict 'refs'; @target_isa = @{"${target}::ISA"} };

    if (@target_isa) {    #only in the main class, not a role

        ## no critic (ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval, ValuesAndExpressions::ProhibitImplicitNewlines)
        eval "#line ${\(__LINE__+1 . ' ' . __FILE__)}\n" . '{
        package ' . $target . ';
        use MRO::Compat ();

            sub _options_data {
                my ( $class, @meta ) = @_;
                return $class->maybe::next::method(@meta);
            }

            sub _options_config {
                my ( $class, @params ) = @_;
                return $class->maybe::next::method(@params);
            }

        1;
        }';

        croak($@) if $@;

        $around->(
            _options_config => sub {
                my ( $orig, $self ) = ( shift, shift );
                return $self->$orig(@_), %$options_config;
            }
        );

        ## use critic
    }
    else {
        if ( $options_config->{with_config_from_file} ) {
            croak(
                "Please, don't use the option <with_config_from_file> into a role."
            );
        }
    }

    my $options_data = {};
    if ( $options_config->{with_config_from_file} ) {
        $options_data->{config_prefix} = {
            format => 's',
            doc    => 'config prefix',
            order  => 0,
        };
        $options_data->{config_files} = {
            format => 's@',
            doc    => 'config files',
            order  => 0,
        };
    }

    my $apply_modifiers = sub {
        return if $target->can('new_with_options');
        $with->('MooX::Options::Role');
        if ( $options_config->{with_config_from_file} ) {
            $with->('MooX::ConfigFromFile::Role');
        }
        if ( $options_config->{with_locale_textdomain_oo} ) {
            $with->('MooX::Locale::TextDomain::OO');
            use_module("MooX::Options::Descriptive::Usage");
            MooX::Options::Descriptive::Usage->can("localizer")
                or MooX::Options::Descriptive::Usage->can("with")
                ->("MooX::Locale::TextDomain::OO");
        }

        $around->(
            _options_data => sub {
                my ( $orig, $self ) = ( shift, shift );
                return ( $self->$orig(@_), %$options_data );
            }
        );
    };

    my @banish_keywords
        = qw/h help man usage option new_with_options parse_options options_usage _options_data _options_config/;
    if ( $options_config->{with_config_from_file} ) {
        push @banish_keywords, qw/config_files config_prefix config_dirs/;
    }

    my $option = sub {
        my ( $name, %attributes ) = @_;
        for my $ban (@banish_keywords) {
            croak(
                "You cannot use an option with the name '$ban', it is implied by MooX::Options"
            ) if $name eq $ban;
        }

        my %_moo_attrs = _filter_attributes(%attributes);
        $has->( $name => %_moo_attrs ) if %_moo_attrs;

        ## no critic (RegularExpressions::RequireExtendedFormatting)
        $name =~ s/^\+//;    # one enhances an attribute being an option
        $options_data->{$name}
            = { _validate_and_filter_options(%attributes) };

        $apply_modifiers->();
        return;
    };

    if ( my $info = $Role::Tiny::INFO{$target} ) {
        $info->{not_methods}{$option} = $option;
    }

    { no strict 'refs'; *{"${target}::option"} = $option; }

    $apply_modifiers->();

    return;
}

my %filter_key = map { $_ => 1 } ( @OPTIONS_ATTRIBUTES, 'negativable' );

sub _filter_attributes {
    my %attributes = @_;
    return map { ( $_ => $attributes{$_} ) }
        grep { !exists $filter_key{$_} } keys %attributes;
}

sub _validate_and_filter_options {
    my (%options) = @_;
    $options{doc} = $options{documentation} if !defined $options{doc};
    $options{order} = 0 if !defined $options{order};

    if ( $options{json}
        || ( defined $options{format} && $options{format} eq 'json' ) )
    {
        delete $options{repeatable};
        delete $options{autosplit};
        delete $options{autorange};
        delete $options{negativable};
        delete $options{negatable};
        $options{json}   = 1;
        $options{format} = 's';
    }

    if ( $options{autorange} and not defined $options{autosplit} ) {

# XXX maybe we should warn here since a previously beloved feature isn't enabled automatically
        eval { use_module("Data::Record"); use_module("Regexp::Common"); }
            and $options{autosplit} = ',';
    }

    exists $options{negativable}
        and $options{negatable} = delete $options{negativable};

    my %cmdline_options = map { ( $_ => $options{$_} ) }
        grep { exists $options{$_} } @OPTIONS_ATTRIBUTES, 'required';

    $cmdline_options{repeatable} = 1
        if $cmdline_options{autosplit} or $cmdline_options{autorange};
    $cmdline_options{format} .= "@"
        if $cmdline_options{repeatable}
        && defined $cmdline_options{format}
        && substr( $cmdline_options{format}, -1 ) ne '@';

    croak(
        "Negatable params is not usable with non boolean value, don't pass format to use it !"
        )
        if ( $cmdline_options{negatable} )
        and defined $cmdline_options{format};

    return %cmdline_options;
}

1;

__END__

=head1 NAME

MooX::Options - Explicit Options eXtension for Object Class

=head1 SYNOPSIS

In myOptions.pm :

  package myOptions;
  use Moo;
  use MooX::Options;

  option 'show_this_file' => (
      is => 'ro',
      format => 's',
      required => 1,
      doc => 'the file to display'
  );
  1;

In myTool.pl :

  use myOptions;
  use Path::Class;

  my $opt = myOptions->new_with_options;

  print "Content of the file : ",
       file($opt->show_this_file)->slurp;

To use it :

  perl myTool.pl --show_this_file=myFile.txt
  Content of the file: myFile content

The help message :

  perl myTool.pl --help
  USAGE: myTool.pl [-h] [long options...]

      --show_this_file: String
          the file to display

      -h --help:
          show this help message

      --man:
          show the manual

The usage message :

  perl myTool.pl --usage
  USAGE: myTool.pl [ --show_this_file=String ] [ --usage ] [ --help ] [ --man ]

The manual :

  perl myTool.pl --man

=head1 DESCRIPTION

Create a command line tool with your L<Moo>, L<Moose> objects.

Everything is explicit. You have an C<option> keyword to replace the usual C<has> to explicitly use your attribute into the command line.

The C<option> keyword takes additional parameters and uses L<Getopt::Long::Descriptive>
to generate a command line tool.

=head1 IMPORTANT CHANGES IN 4.100

=head2 Enhancing existing attributes

One can now convert an existing attribute into an option for obvious reasons.

  package CommonRole;

  use Moo::Role;

  has attr => (is => "ro", ...);

  sub common_logic { ... }

  1;

  package Suitable::Cmd::CLI;

  use Moo;
  use MooX::Cmd;
  use MooX::Options;

  with "CommonRole";

  option '+attr' => (format => 's', repeatable => 1);

  sub execute { shift->common_logic }

  1;

  package Suitable::Web::Request::Handler;

  use Moo;

  with "CommonRole";

  sub all_suits { shift->common_logic }

  1;

  package Suitable::Web;

  use Dancer2;
  use Suitable::Web::Request::Handler;

  set serializer => "JSON";

  get '/suits' => sub {
      $my $reqh = Suitable::Web::Request::Handler->new( attr => config->{suit_attr} );
      $reqh->all_suits;
  };

  dance;

  1;

Of course there more ways to to it, L<Jedi> or L<Catalyst> shall be fine, either.

=head2 Rename negativable into negatable

Since users stated that C<negativable> is not a reasonable word, the flag is
renamed into negatable. Those who will 2020 continue use negativable might
or might not be warned about soon depreciation.

=head2 Replace Locale::TextDomain by MooX::Locale::Passthrough

L<Locale::TextDomain> is broken (technically and functionally) and causes a
lot of people to avoid C<MooX::Options> or hack around. Both is unintened.

So introduce L<MooX::Locale::Passthrough> to allow any vendor to add reasonable
localization, eg. by composing L<MooX::Locale::TextDomain::OO> into it's
solution and initialize the localization in a reasonable way.

=head2 Make lazy loaded features optional

Since some features aren't used on a regular basis, their dependencies have
been downgraded to C<recommended> or C<suggested>. The optional features are:

=over 4

=item autosplit

This feature allowes one to split option arguments at a defined character and
always return an array (implicit flag C<repeatable>).

  option "search_path" => ( is => "ro", required => 1, autosplit => ":", format => "s" );

However, this feature requires following modules are provided:

=over 4

=item *

L<Data::Record>

=item *

L<Regexp::Common>

=back

=item json format

This feature allowes one to invoke a script like

  $ my-tool --json-attr '{ "gem": "sapphire", "color": "blue" }'

It might be a reasonable enhancement to I<handles>.

Handling JSON formatted arguments requires any of those modules
are loded:

=over 4

=item *

L<JSON::MaybeXS>

=item *

L<JSON::PP> (in Core since 5.14).

=back

=back

=head2 Decouple autorange and autosplit

Until 4.023, any option which had autorange enabled got autosplit enabled, too.
Since autosplit might not work correctly and for a reasonable amount of users
the fact of

  $ my-tool --range 1..5

is all they desire, autosplit will enabled only when the dependencies of
autosplit are fulfilled.

=head1 IMPORTED METHODS

The list of the methods automatically imported into your class.

=head2 new_with_options

It will parse your command line params and your inline params, validate and call the C<new> method.

  myTool --str=ko

  t->new_with_options()->str # ko
  t->new_with_options(str => 'ok')->str #ok

=head2 option

The C<option> keyword replaces the C<has> method and adds support for special options for the command line only.

See L</OPTION PARAMETERS> for the documentation.

=head2 options_usage | --help

It displays the usage message and returns the exit code.

  my $t = t->new_with_options();
  my $exit_code = 1;
  my $pre_message = "str is not valid";
  $t->options_usage($exit_code, $pre_message);

This method is also automatically fired if the command option "--help" is passed.

  myTool --help

=head2 options_man | --man

It displays the manual.

  my $t = t->new_with_options();
  $t->options_man();

This is automatically fired if the command option "--man" is passed.

  myTool --man

=head2 options_short_usage | --usage

It displays a short version of the help message.

  my $t = t->new_with_options();
  $t->options_short_usage($exit_code);

This is automatically fired if the command option "--usage" is passed.

  myTool --usage

=head1 IMPORT PARAMETERS

The list of parameters supported by L<MooX::Options>.

=head2 flavour

Passes extra arguments for L<Getopt::Long::Descriptive>. It is useful if you
want to configure L<Getopt::Long>.

  use MooX::Options flavour => [qw( pass_through )];

Any flavour is passed to L<Getopt::Long> as a configuration, check the doc to see what is possible.

=head2 protect_argv

By default, C<@ARGV> is protected. If you want to do something else on it, use this option and it will change the real C<@ARGV>.

  use MooX::Options protect_argv => 0;

=head2 skip_options

If you have Role with options and you want to deactivate some of them, you can use this parameter.
In that case, the C<option> keyword will just work like an C<has>.

  use MooX::Options skip_options => [qw/multi/];

=head2 prefer_commandline

By default, arguments passed to C<new_with_options> have a higher priority than the command line options.

This parameter will give the command line an higher priority.

  use MooX::Options prefer_commandline => 1;

=head2 with_config_from_file

This parameter will load L<MooX::Options> in your module. 
The config option will be used between the command line and parameters.

myTool :

  use MooX::Options with_config_from_file => 1;

In /etc/myTool.json

  {"test" : 1}

=head2 with_locale_textdomain_oo

This Parameter will load L<MooX::Locale::TextDomain::OO> into your module as
well as into L<MooX::Options::Descriptive::Usage>.

No further action is taken, no language is chosen - everything keep in
control.

Please read L<Locale::TextDomain::OO> carefully how to enable the desired
translation setup accordingly.

=head1 usage_string

This parameter is passed to Getopt::Long::Descriptive::describe_options() as
the first parameter.  

It is a "sprintf"-like string that is used in generating the first line of the
usage message. It's a one-line summary of how the command is to be invoked. 
The default value is "USAGE: %c %o".

%c will be replaced with what Getopt::Long::Descriptive thinks is the
program name (it's computed from $0, see "prog_name").

%o will be replaced with a list of the short options, as well as the text
"[long options...]" if any have been defined.

The rest of the usage description can be used to summarize what arguments
are expected to follow the program's options, and is entirely free-form.

Literal "%" characters will need to be written as "%%", just like with
"sprintf".

=head2 spacer

This indicate the char to use for spacer. Please only use 1 char otherwize the text will be too long.

The default char is " ".

  use MooX::Options space => '+'

Then the "spacer_before" and "spacer_after" will use it for "man" and "help" message.

  option 'x' => (is => 'ro', spacer_before => 1, spacer_after => 1);

=head1 OPTION PARAMETERS

The keyword C<option> extend the keyword C<has> with specific parameters for the command line.

=head2 doc | documentation

Documentation for the command line option.

=head2 long_doc

Documentation for the man page. By default the C<doc> parameter will be used.

See also L<Man parameters|MooX::Options::Manual::Man> to get more examples how to build a nice man page.

=head2 required

This attribute indicates that the parameter is mandatory.
This attribute is not really used by L<MooX::Options> but ensures that consistent error message will be displayed.

=head2 format

Format of the params, same as L<Getopt::Long::Descriptive>.

=over

=item * i : integer

=item * i@: array of integer

=item * s : string

=item * s@: array of string

=item * f : float value

=back

By default, it's a boolean value.

Take a look of available formats with L<Getopt::Long::Descriptive>.

You need to understand that everything is explicit here. 
If you use L<Moose> and your attribute has C<< isa => 'Array[Int]' >>, that will B<not> imply the format C<i@>.

=head2 format json : special format support

The parameter will be treated like a json string.

  option 'hash' => (is => 'ro', json => 1);

You can also use the json format

  option 'hash' => (is => 'ro', format => "json");

  myTool --hash='{"a":1,"b":2}' # hash = { a => 1, b => 2 }

=head2 negatable

It adds the negative version for the option.

  option 'verbose' => (is => 'ro', negatable => 1);

  myTool --verbose    # verbose = 1
  myTool --no-verbose # verbose = 0

The former name of this flag, negativable, is discouraged - since it's not a word.

=head2 repeatable

It appends to the L</format> the array attribute C<@>.

I advise to add a default value to your attribute to always have an array.
Otherwise the default value will be an undefined value.

  option foo => (is => 'rw', format => 's@', default => sub { [] });

  myTool --foo="abc" --foo="def" # foo = ["abc", "def"]

=head2 autosplit

For repeatable option, you can add the autosplit feature with your specific parameters.

  option test => (is => 'ro', format => 'i@', default => sub {[]}, autosplit => ',');
  
  myTool --test=1 --test=2 # test = (1, 2)
  myTool --test=1,2,3      # test = (1, 2, 3)
  
It will also handle quoted params with the autosplit.

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autosplit => ',');

  myTool --testStr='a,b,"c,d",e,f' # testStr ("a", "b", "c,d", "e", "f")

=head2 autorange

For another repeatable option you can add the autorange feature with your specific parameters. This 
allows you to pass number ranges instead of passing each individual number.

  option test => (is => 'ro', format => 'i@', default => sub {[]}, autorange => 1);
  
  myTool --test=1 --test=2 # test = (1, 2)
  myTool --test=1,2,3      # test = (1, 2, 3)
  myTool --test=1,2,3..6   # test = (1, 2, 3, 4, 5, 6)
  
It will also handle quoted params like C<autosplit>, and will not rangify them.

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autorange => 1);

  myTool --testStr='1,2,"3,a,4",5' # testStr (1, 2, "3,a,4", 5)

C<autosplit> will be set to ',' if undefined. You may set C<autosplit> to a different delimiter than ','
for your group separation, but the range operator '..' cannot be changed. 

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autorange => 1, autosplit => '-');

  myTool --testStr='1-2-3-5..7' # testStr (1, 2, 3, 5, 6, 7) 

=head2 short

Long option can also have short version or aliased.

  option 'verbose' => (is => 'ro', short => 'v');

  myTool --verbose # verbose = 1
  myTool -v        # verbose = 1

  option 'account_id' => (is => 'ro', format => 'i', short => 'a|id');

  myTool --account_id=1
  myTool -a=1
  myTool --id=1

You can also use a shorter option without attribute :

  option 'account_id' => (is => 'ro', format => 'i');

  myTool --acc=1
  myTool --account=1

=head2 order

Specifies the order of the attribute. If you want to push some attributes at the end of the list.
By default all options have an order set to C<0>, and options are sorted by their names.

  option 'at_the_end' => (is => 'ro', order => 999);

=head2 hidden

Hide option from doc but still an option you can use on command line.

  option 'debug' => (is => 'ro', doc => 'hidden');

Or

  option 'debug' => (is => 'ro', hidden => 1);

=head2 spacer_before, spacer_after

Add spacer before or after or both the params

  option 'myoption' => (is => 'ro', spacer_before => 1, spacer_after => 1);

=head1 COMPATIBILITY

=head2 MooX::Options and Mo

C<MooX::Options> is implemented as a frontend loader class and the real magic
provided by a role composed into the caller by C<MooX::Options::import>.

Since some required features (C<with>, C<around>) isn't provided by L<Mo>,
L<Class::Method::Modifiers> must be loaded by any C<Mo> class using C<MooX::Options>,
L<Role::Tiny::With> is needed to I<inject> the L<MooX::Options::Role> and
finally in the target package the private accessors to options_config
and options_data are missing.

Concluding a reasonable support for Mo based classes is beyond the goal of
this module. It's neither forbidden nor actively prevented, but won't be
covered by any test nor actively supported.

If someome wants contribute guides how to use C<MooX::Options> together with
C<Mo> or provide patches to solve this limitation - any support will granted.

=head1 ADDITIONAL MANUALS

=over

=item * L<Man parameters|MooX::Options::Manual::Man>

=item * L<Using namespace::clean|MooX::Options::Manual::NamespaceClean>

=item * L<Manage your tools with MooX::Cmd|MooX::Options::Manual::MooXCmd>

=back

=head1 EXTERNAL EXAMPLES

=over

=item * L<Slide3D about MooX::Options|http://perltalks.celogeek.com/slides/2012/08/moox-options-slide3d.html>

=back

=head1 Translation

Translation is now supported.

Use the dzil command to update the pot and merge into the po files.

=over

=item * dzil msg-init

Create a new language po

=item * dzil msg-scan

Scan and generate or update the pot file

=item * dzil msg-merge

Update all languages using the pot file

=back

=head2 THANKS

=over

=item * sschober

For implementation and German translation.

=back

=head1 THANKS

=over

=item * Matt S. Trout (mst) <mst@shadowcat.co.uk>

For his patience and advice.

=item * Tomas Doran (t0m) <bobtfish@bobtfish.net>

To help me release the new version, and using it :)

=item * Torsten Raudssus (Getty)

to use it a lot in L<DuckDuckGo|http://duckduckgo.com> (go to see L<MooX> module also)

=item * Jens Rehsack (REHSACK)

Use with L<PkgSrc|http://www.pkgsrc.org/>, and many really good idea (L<MooX::Cmd>, L<MooX::Options>, and more to come I'm sure)

=item * All contributors

For improving and add more feature to MooX::Options

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Options

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Options>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Options>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-Options>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Options/>

=back

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This software is copyright (c) 2017 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
