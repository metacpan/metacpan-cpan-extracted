package Term::Interact;

=head1 NAME

Term::Interact - Interactively Get Validated Data

=head1 SYNOPSIS

  use Term::Interact;

  my $ti = Term::Interact->new( @args );

  # get validated data interactively
  $validated_data = $ti->get( @args );

  # check existing data non-interactively
  die "Invalid!" unless $ti->validate( $data, @args );

=head1 DESCRIPTION

Term::Interact enables you to interactively get validated data from a user.  This is accomplished via a I<simple> API, wherein you specify various parameters for prompting the user, as well as "checks" with which gotten data will be validated.

=head1 EXAMPLES

 # set up object with some optional parameters
 my $ti = Term::Interact->new(

   # set desired date formatting behavior
   # (See perldoc Date::Manip for syntax)
   date_format_display  =>  '%d-%b-%Y',
   date_format_return   =>  '%s',

   # database handle (see perldoc DBI) to
   # allow sql_checks.
   dbh  =>  $dbh,
 );

 my $num1 = $ti->get(
   msg        =>  'Enter a single digit number.',
   prompt     =>  'Go ahead, make my day: ',
   re_prompt  =>  'Try Again Here: ',
   check      =>  [
                    qr/^\d$/,
                    '%s is not a single digit number!'
                  ],
 );
 #
 # Resulting Interaction looks like:
 #
 # Enter a single digit number.
 #    Go ahead, make my day: w
 #    'w' is not a single digit number!
 #    Try Again Here: 23
 #    '23' is not a single digit number!
 #    Try Again Here: 2

 my $date = $ti->get (
   type     =>  'date',
   name     =>  'Date from 2001',
   confirm  =>  1,
   check    =>  [
                  ['<= 12-31-2001', '%s is not %s.'],
                  ['>= 01/01/2001', '%s is not %s.'],
                ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Date from 2001: Enter a value.
 #    > 2002-03-12
 #    You entered: '12-Mar-2002'. Is this correct? (Y|n)
 #    '12-Mar-2002' is not <= 31-Dec-2001.
 #    > foo
 #    'foo' is not a valid date
 #    > 2000-12-31
 #    You entered: '31-Dec-2000'. Is this correct? (Y|n)
 #    '31-Dec-2000' is not >= 01/01/2001.
 #    > 2001-02-13
 #    You entered: '13-Feb-2001'. Is this correct? (Y|n)

 my $states_aref = $ti->get (
   msg        =>  'Please enter a comma delimited list of states.',
   prompt     =>  'State: ',
   re_prompt  =>  'Try Again: ',
   delimiter  =>  ',',
   case       =>  'uc',
   dbh        =>  $dbh,
   check      =>  [
                    'SELECT state FROM states ORDER BY state',
                    '%s is not a valid state code.  Valid codes are: %s'
                  ],
 );
 #
 # Resulting Interaction looks like:
 #
 # Please enter a comma delimited list of states.
 #    State: FOO
 #    'FOO' is not a valid state code.  Valid codes are: AA, AB, AE, AK,
 #    AL, AP, AQ, AR, AS, AZ, BC, CA, CO, CT, CZ, DC, DE, FL, FM, GA, GU,
 #    HI, IA, ID, IL, IN, KS, KY, LA, LB, MA, MB, MD, ME, MH, MI, MN, MO,
 #    MP, MS, MT, NB, NC, ND, NE, NF, NH, NJ, NM, NS, NT, NV, NY, OH, OK,
 #    ON, OR, PA, PE, PQ, PR, PW, RI, RM, SC, SD, SK, TN, TT, TX, UT, VA,
 #    VI, VT, WA, WI, WV, WY, YT
 #    Try Again: az, pa


 my $num2 = $ti->get (
   name   =>  'Number Less Than 10 and More than 3',
   check  =>  [
                [' < 10', '%s is not less than 10.'],
                ['>3', '%s is not %s.'],
              ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Number Less Than 10 and More than 3: Enter a value.
 #    > f
 #    'f' is not numeric.
 #    > 1
 #    '1' is not > 3.
 #    > -1
 #    '-1' is not > 3.
 #    > 14
 #    '14' is not less than 10.
 #    > 5

 my $grades = $ti->get (
   name       =>  'Letter grade',
   delimiter  =>  ',',
   check      =>  [ 'A', 'B', 'C', 'D', 'F' ],
 );
 #
 # Resulting Interaction looks like:
 #
 # Letter grade: Enter a value or list of values delimited with commas.
 #    > 1
 #    > s
 #    > X
 #    > a, b
 #    > A, B, C


 # If multiple checks are specified, the ordering
 # is preserved.  In the example below, the sql_check
 # will be applied before the regex_check.
 my $foo = $ti->get (
   name       =>  $name,
   delimiter  =>  $delim,
   check      =>  [ 'SELECT foo FROM bar', qr/aaa|bbb|ccc/ ],
 );

 # multiple requests in one call to get method
 my ($foo, $bar) = $ti->get (
   [
     [
       name   =>  'foo',
       check  =>  [qw/ A B C /],
     ],

     # you can use an href if you prefer
     {
       name       =>  'bar',
       delimiter  =>  ',',
       check      =>  qr/kermit|der|frosch/,
     },
   ]
 );

=head1 METHODS

=over 2

=item C<new>

The C<new> method constructs a Term::Interact object using default values and passed in key=>value parameters (see PARAMETERS section below).  The parameter values stored in the object are subsequently accessible for reading and setting via methods named the same as the parameters.  For example:

    # get the value of the date_format_return parameter
    my $fmt = $ti->date_format_return;

    # set the value of the date_format_return parameter
    # to DD-Mon-YYYY
    $ti->date_format_return( '%d-%b-%Y' );

=item C<get>

The C<get> method prompts the user for data and, if a C<check> parameter (see C<check> in the PARAMETERS section below) has been passed in, invokes the C<validate> method to validate the user-provided data.

=item C<validate>

The C<validate> method accepts the data to be validated as its first parameter, and then the same key=>value parameters that C<new> and C<get> accept.  One of these parameters needs to be the C<check> parameter so that validation can be performed.

=item C<new_check>

The C<new_check> method uses a C<check> parameter value to construct one or more check objects (which are returned in an aref).  You'll not usually invoke this method, because the C<validate> method transparently invokes it to transform its C<check> parameter value into a collection of check objects.  (These check objects are what the internal check methods actually use to validate data.)  Nonetheless, you may invoke this method if you like.  By doing so you could initially set the C<check> parameter to an aref of check objects when invoking C<get> or C<validate>.

=item C<parameters>

The C<parameters> method returns information about available parameters.  If called with no args, it will return a list of available parameter names in list context, or an href of all parameter information in scalar context:
  {
    interact => {type => 'bool', default => 1             },
    name     => {type => 'str',                           } ,
    ...
    check    => {type => ['str','aref','qr//','coderef'], }
  }

If called with a specific type, ala $ti->parameter(type => 'bool'), a list of parameters matching that type will be returned in list context, or an aref of parameter_name => type pairs will be returnes in scalar context.  Also note that not-types are available, ala $ti->parameter(type => '!bool').

If called with the key value pair (default => 1), the method will return a list of parameters that have default values.  If called this way in scalar context, the method will return an aref of parameter_name => default_value key value pairs.

All of the parameters are listed below in the PARAMETER section, and are all accessible via self-named mutator/accessor mehods.  

=back

=head2 PARAMETERS

These parameters are available for use with C<new>, where they will be stored within the constructed object.  They are also available for use with the C<get> and C<validate> methods, where they will override any values stored in the object, but only for the duration of that method call.  In other words, the parameter values stored in the object during construction will be temporarilly overriden, but not changed by, any variant parameter values subsequently supplied to C<get> or C<validate>.  The parameter values stored in the object may be changed, however, by invoking the self-named method accessor/mutators, ala $ti->timeout( 30 ).

=over 2

=item C<interact>

I<bool>: Defaults to 1, of course, but you may turn interact mode off.  In that case the validate method works as normal, but the get method will simply return the default value (or die if none is set).

=item C<name>

I<str>: Used in auto-assembling a message for the user if no msg parameter was specified.

=item C<type>

I<str>: Currently, the only meaningful value for this parameter is 'date'.  If set to date, all input from the user and all check values supplied by the programmer will be parsed as dates by Date::Manip.

=item C<allow_null>

I<bool>: Defaults to 0.  Set to 1 to allow user to enter 'NULL', regardless of any other checking.  This is useful for database related prompting.

=item C<timeout>

I<num>: Defaults to 600 seconds.  Set to 0 to turn off the timeout functionality.  Timeout results in a fatal error which you may catch as you like.  (The timeout parameter will be ignored under MS Windows, where its functionality is not possible.)

=item C<maxtries>

I<num>: Defaults to 20.  Set to 0 turn off the maxtries functionality.  Exceeding the maxtries results in a fatal error which you may catch as you like.

=item C<shared_autoformat_args>

I<href>: Defaults to {all => 1, fill => 0, right => [ the value of C<term_width> ]}.  The autoformat method from Text::Autoformat is used to format everything printed to FH_OUT.  This href will be passed to autoformat every time it is invoked.

=item C<menu>

I<str>: Menu that will print prior to msg.  No formatting will be performed on the menu.  No menu will be printed unless this value is set.

=item C<msg>

I<str>: Message that will print prior to user input prompt.  No msg will be printed if defined as 0.  If left undefined, a message will be auto-generated based on other parameter values.

=item C<succinct>

I<bool>: Defaults to 0.  If set to 1:  If a parm name was given, it will be used as a msg.  Otherwise the msg will be set to ''.  If a default value was provided, the default prompt will be '[default_value]> ' instead of the normal default prompt. 

=item C<msg_indent>

I<num>: Defaults to 0.  Number of spaces that message will be indented from the terminal's left margin when output to FH_OUT.

=item C<msg_newline>

I<num>: Defaults to 1.  The number of newlines prepended to msg when it is printed to FH_OUT.

=item C<prompt>

I<str>: Defaults to '> '.  User will be prompted for input with this string.

=item C<reprompt>

I<str>: User will be re-prompted for input (as necessary) with this string.  If not set, the value of C<prompt> will be used instead.

=item C<prompt_indent>

I<num>: Defaults to 4.  Number of spaces that all prompts will be indented from the terminal's left margin when output to FH_OUT.

=item C<case>

I<str>: If specified, the case of user input will be adjusted prior to validation.  The uc, lc, and ucfirst operators may be specified.

=item C<confirm>

I<bool>: Defaults to 0.  The user will be prompted to confirm the input if set to 1.

=item C<echo>

I<bool>: Defaults to 0.  If set to 1, the get method will echo the user's validated choice to FH_OUT just prior to returning.

=item C<echo_quote>

I<str>: Defaults to "'" (a single quote).  Whenever user input is echoed to the terminal, it will be quoted with whatever character string is found here, if any.

=item C<delimiter>

I<str>: Set this parameter to allow the user to enter multiple values via delimitation.  Note this is a string value, not a pattern.

=item C<delimiter_spacing>

I<bool>: Defaults to 1, allowing user to add whitespace to either or both sides of the delimiter when entering a list of values.  Whitespace before and after any delimiters will then be discarded when reading user input.

=item C<min_elem>

I<num>: Set this parameter to require the user to enter a minimum number of values.  Note this is a meaningful parameter only when used in conjunction with C<delimiter>.

=item C<max_elem>

I<num>: Set this parameter to restrict the user to a maximum number of values they can enter.  Note this is a meaningful parameter only when used in conjunction with C<delimiter>.

=item C<unique_elem>

I<bool>: Set this parameter to require all elements of the user-entered delimited value list to be unique.  Note this is a meaningful parameter only when used in conjunction with C<delimiter>.

=item C<default>

I<str> or I<aref>: If the user is permitted to input multiple values (i.e., you have specified a delimiter), you may specify multiple default values by passing them in an aref.  In any case you may pass in one default value as a string.

=item C<check_default>

I<bool>: Defaults to 0.  If the user elects to use the default value(s), those value(s) will not be validated by any specified checks unless this parameter is set to 1.

=item C<date_format_display>

I<str>:  Defaults to '%c'.  This string is used to format any dates being printed to FH_OUT.  See the UnixDate function from perldoc Date::Manip for details.  Note this is a meaningful parameter only when used in conjunction if C<type> is set to date.

=item C<date_format_return>

I<str>:  Defaults to '%c'.  This string is used to format dates returned by the C<get> and C<validate> methods.  See Date::Manip's UnixDate function for details.  Note this is a meaningful parameter only when used in conjunction if C<type> is set to date.

=item C<FH_OUT>

I<FH>: Defaults to STDOUT.  This filehandle will be used to print any messages to the user.

=item C<FH_IN>

I<FH>: Defaults to STDIN.  This filehandle will be used to read any input from the user.

=item C<term_width>

I<num>: Defaults to 72.  If the term_width of FH_OUT is less than the default or a value that you provide, the FH_OUT term_width will be used instead.

=item C<ReadMode>

I<num>:  Sets the ReadMode for FH_IN during user prompting.  Useful for turning terminal echo off for getting passwords; see Term::ReadKey for details.  If this parameter is used, the ReadMode for FH_IN will be reset to 0 after each user input and in END processing.

=item C<dbh>

I<obj>:  This is the database handle needed to execute any sql_checks.  See perldoc DBI for details.

=item C<translate>

I<aref>:  Translates validated user input into something else.  Useful, for example, when you require the user to enter only one character for the sake of convenience, but you really want something more verbose returned.  The aref may contain one or more translation rules, each of which is comprised of a check (see below) and a translation string.  For example, when calling C<get> with the following, a validated user input of 'p' would be translated into the string 'portrait' before being returned to you:

    translate   =>  [
                        [ 'eq p'  => 'portrait' ],
                        [ 'eq l'  => 'landscape' ],
                    ]

=item C<check>

I<str, aref, qr//, coderef>:  This parameter accepts one string, one aref, one compiled regular expression (qr//), or one coderef.  With these options you will be able to indicate one or more of the following kinds of checks to be used in validating data, as well as any error message you would like for each of the checks.

CHECK VARIETIES

Term::Interact comes with support for six varieties of check expressions:

=over 2

=item sql_check

I<str>:  A SQL statement (i.e. 'SELECT field FROM table').  Will be used to generate a list of validation values from a database.  Valid data is that which appears in the list.

=item regex_check

I<qr//>:  A compliled regular expression used to validate data.  Valid data is that which matches the regular expression.

=item list_check

I<aref>:  An aref of values used to validate data.  Valid data is that which appears in the list.

=item compare_check

I<str>:  A comparison test in string form.  Valid data is that which satisfies the comparison test.

=item filetest_check

I<str>:  A filetest operator in string form.  Valid data is that which satisfies the filetest operator.

=item custom_check

I<coderef>:  For special occasions (or to make use of Perl's built in functions), you can write your own custom check.  This must be a reference to a function that accepts one value and returns true if that value is valid.  Example:  check => [ sub{getgrnam shift}, '%s is not a valid group' ]

=back 2

SYNTAX

=over 2

Possible values when specifying a single check:

=over 2

  [   $check_aref,    $err_str    ]
           -or-
  [   $check_aref                 ]
           -or-
      $check_aref
           -or-
  [   $check_regex,   $err_str    ]
           -or-
  [   $check_regex                ]
           -or-
      $check_regex
           -or-
  [   $check_str,     $err_str    ]
           -or-
  [   $check_str                  ]
           -or-
      $check_str

=back 2

Possible values when specifying multiple checks:

=over 2

  [
    [ $check_aref,    $err_str  ],
    [ $check_aref               ],
      $check_aref,
    [ $check_regex,   $err_str  ],
    [ $check_regex              ],
      $check_regex,
    [ $check_str,     $err_str  ],
    [ $check_str                ],
      $check_str,
  ]

=back 2

NOTE

=over 2

This module steers clear of offering explicit checks like 'phone_number_check' or 'email_address_check'.  In the author's opinion one may generally obtain all the convenience and code readability one needs via the built in varieties of checks.  However, if you have regular need for an additional check you'll likely want to steer clear of the built in custom_check option (see above).  You can more permanently add your own custom checks by subclassing Term::Interact and providing the desired checks as subroutines (all the check subs follow a simple API, just follow the pattern).  Additionally you will need to modify the private _classify_check_type function.

=back 2

=back 2

=cut

#use diagnostics;
use strict;

# alarm not available under MS Windows
unless ($^O eq 'MSWin32') {
    use sigtrap 'handler' => sub{die "\n\nTimed out waiting for user input!\n"}, 'ALRM';
}

# trap interrupts
use sigtrap qw( die INT );

# make sure ReadMode is reset whe we're done
END {  ReadMode(0)  }

use Text::Autoformat;
use Term::ReadKey;
use Date::Manip;
use File::Spec;

use vars qw( $VERSION $AUTOLOAD );

$VERSION = '0.50';

sub parameters {
    shift;
    my $wantarray = wantarray;
    my %args = @_;

    # create a read-only data structure
    my $parms = \{
        interact                =>  {type=>'bool',  default=>1,             },
        name                    =>  {type=>'str',                           },
        type                    =>  {type=>'str',                           },
        allow_null              =>  {type=>'bool',  default=>0,             },
        timeout                 =>  {type=>'num',   default=>600,           },
        maxtries                =>  {type=>'num',   default=>20,            },
        shared_autoformat_args  =>  {type=>'href',                          },
        menu                    =>  {type=>'str',                           },
        msg                     =>  {type=>'str',                           },
        succinct                =>  {type=>'bool',  default=>0,             },
        msg_indent              =>  {type=>'num',   default=>0,             },
        msg_newline             =>  {type=>'num',   default=>1,             },
        prompt                  =>  {type=>'str',   default=>'> ',          },
        reprompt                =>  {type=>'str',                           },
        prompt_indent           =>  {type=>'num',   default=>4,             },
        case                    =>  {type=>'str',                           },
        confirm                 =>  {type=>'bool',  default=>0,             },
        echo                    =>  {type=>'bool',  default=>0,             },
        echo_quote              =>  {type=>'str',   default=>"'",           },
        delimiter               =>  {type=>'str',                           },
        delimiter_spacing       =>  {type=>'bool',  default=>1,             },
        min_elem                =>  {type=>'num',                           },
        max_elem                =>  {type=>'num',                           },
        unique_elem             =>  {type=>'bool',                          },
        default                 =>  {type=>['str','aref'],                  },
        check_default           =>  {type=>'bool',  default=>0,             },
        date_format_display     =>  {type=>'str',   default=>'%c',          },
        date_format_return      =>  {type=>'str',   default=>'%c',          },
        FH_OUT                  =>  {type=>'glob',  default=>\*STDOUT,      },
        FH_IN                   =>  {type=>'glob',  default=>\*STDIN,       },
        term_width              =>  {type=>'num',   default=>72,            },
        ReadMode                =>  {type=>'num',                           },
        dbh                     =>  {type=>'obj',   default=>'',            },
        translate               =>  {type=>'aref',                          },
        check                   =>  {type=>['str','aref','qr//','coderef'], },
    };

    if ($args{type}) {
        my @return;
        # allow processing of types that start with ! (not)
        my $not = $args{type} =~ s/^!//;
        if ($not) {
            @return = map
            {
                # if an aref
                if (ref $$parms->{$_}{type}) {
                    my $key = $_;
                    !grep( /$args{type}/, @{$$parms->{$key}{type}} )
                    ?
                        $wantarray
                        ? $key
                        : ($key => $$parms->{$key}{type})
                    : ()
                } else {
                    $$parms->{$_}{type} ne $args{type}
                    ?
                        $wantarray
                        ? $_
                        : ($_ => $$parms->{$_}{type})
                    : ()
                }
            } keys %{$$parms};

        } else {
            @return = map
            {
                # if an aref
                if (ref $$parms->{$_}{type}) {
                    my $key = $_;
                    grep( $key, @{$$parms->{$_}{type}} )
                    ?
                        $wantarray
                        ? $key
                        : ($key => $$parms->{$_}{type})
                    : ()
                } else {
                    $$parms->{$_}{type} eq $args{type}
                    ?
                        $wantarray
                        ? $_
                        : ($_ => $$parms->{$_}{type})
                    : ()
                }
            } keys %{$$parms};
        }
        # return list of parms or href with relevant parm=>type pairs
        return $wantarray ? @return : { @return };

    } elsif ($args{default}) {
        my @return = map
        {
            exists $$parms->{$_}{default}
            ? (
                $wantarray
                ? $_
                : ($_, $$parms->{$_}{default})
              )
            : ()
        } keys %{$$parms};

        # return list of parms or href with relevant parm=>default pairs
        return $wantarray ? @return : { @return };
    }

    # all other cases
    return $wantarray ? keys %{$$parms} : $$parms;
}


sub new {
    my $class = shift;
    my $self = bless {} => $class;
    my $args = $self->process_args( @_ );
    for (keys %{ $args }) {
        $self->{$_} = $args->{$_};
    }
    return $self;
}

# regex for recognizing a date already in epoch form -- used by more than one method()
my $qr_epoch = qr/^\-?\d+$/;

sub process_args {
    my $self = shift;

    ### @_ processing
    # we'll accept key value pairs as an array, aref, or an href
    if ($#_ == 0) {
        if (ref $_[0] eq 'HASH') {
            @_ = %{ $_[0] };
        } elsif (ref $_[0] eq 'ARRAY') {
            @_ = @{ $_[0] };
        } else {
            die "invalid arg";
        }
    }
    my %args = @_;

    ### $self processing
    # use anything from self that hasn't been specified by args
    for (keys %{$self}) {
        unless (exists $args{$_}) {
            $args{$_} = $self->{$_};
        }
    }

    my $defaults = $self->parameters(default=>1);

    for (keys %{$defaults}) {
        unless (exists $args{$_}) {
            $args{$_} = $defaults->{$_};
        }
    }

    # get term width settings if we can, otherwise we'll silently move on
    open SAVEERR, ">&STDERR" or die;
    open STDERR, ">" . File::Spec->devnull or die;
    eval {
        my ($width) = GetTerminalSize( $args{FH_OUT} );
        $args{term_width} = ($width < $args{term_width} ? $width : $args{term_width});
    };
    open STDERR, ">&SAVEERR" or die;
    close SAVEERR;

    # autoformat settings
    $args{shared_autoformat_args} = {all => 1, fill => 0, right => $args{term_width}};

    ### Date related setup
    if (defined $args{type} and $args{type} eq 'date') {
        # accomodate time zone deficiency of Date::Manip under Win32
        set_TZ( (defined $args{time_zone}) ? $args{time_zone} : undef) if ($^O eq 'MSWin32');

        # set up date preprocessing
        if (defined $args{date_preprocess}) {
            die "date_preprocess value must be a coderef!" unless (ref $args{date_preprocess} eq 'CODE');
        } else {
            # Date::Manip interprets dates in format nn-nn-nnnn in a rather odd way (IMHO)...
            # So, let's trade those dashes for slashes to end up with the desired result
            # from Date::Manip
            my $qr_match = qr/^(\s*\d{2})\-(\d{2})\-(\d{4})/;
            $args{date_preprocess} = sub {
                my $date = shift;
                # switch those dashes to slashes!
                $date =~ s/$qr_match/$1\/$2\/$3/;
                return $date;
            };
        }

        # default the date formatting
        $args{date_format_display} = '%c' unless (defined $args{date_format_display});
        $args{date_format_return} = '%c' unless (defined $args{date_format_return});

        # convert any default value(s) to epoch seconds
        if (defined $args{default}) {
            if (ref $args{default}) {
                die "default value may only be an aref or scalar!" unless (ref $args{default} eq 'ARRAY');
                for (@{ $args{default} }) {
                    unless (/$qr_epoch/) {
                        my $epoch_seconds = UnixDate($args{date_preprocess}->($_),'%s') or die "Could not recognize default value $_ as a date!";
                        $_ = $epoch_seconds;
                    }
                }
            } else {
                unless ($args{default} =~ /$qr_epoch/) {
                    my $epoch_seconds = UnixDate($args{date_preprocess}->($args{default}),'%s') or die "Could not recognize default value $args{default} as a date!";
                    $args{default} = $epoch_seconds;
                }
            }
        }
    }

    return \%args
}

sub new_check {
    shift;
    my $return;

    # get the one or more checks being passed in
    my $raw_checks = shift || die "No check was provided to the new_check constructor";
    if (@_) {
        die "the new_check constructor accepts only one argument, you passed ", (scalar @_)+1;
    }

    my @check_objects;


    my $add_check_object = sub {
        my $check = shift;
        my $err_msg = shift;

        my $href;
        $href->{check} = $check;
        $href->{check_type} = _classify_check_type( $href->{check} );
        $href->{err_msg} = $err_msg if defined $err_msg;

        push @check_objects, bless $href => '_check_object';
    };

    my $process_aref = sub {
        my $aref = shift;

        # []
        if (scalar @$aref == 0) {
            die "the new_check constructor recieved an empty aref inside another aref!";

        # [ ^ ]  -- if only 1 elem it must be a check
        } elsif (scalar @$aref == 1) {
            $add_check_object->( $aref->[0] );

        # [ ^,^ ]
        } elsif (scalar @$aref == 2) {
            # if the first elem is a check
            my $check_type;
            eval { $check_type = _classify_check_type( $aref->[0] ) };
            if ($check_type) {
                if (ref $aref->[1]) {
                    die "the new_check constructor recieved a ref in place of a string error message!";
                }
                $add_check_object->( $aref->[0], $aref->[1] );

            # else this is a 2 element aref check
            } else {
                # this is a list_check, so all elements of @{ $aref } must be non-refs
                for (@{ $aref }) {
                    if (ref) {
                        die "the new_check constructor recieved what was evaluated to be a list_check, but one of its elements was a ref!";
                    }
                }
                $add_check_object->( $aref );
            }

        # [ ^,^,^,... ]
        } elsif (scalar @$aref > 2) {
            # this is a list_check, so all elements of @{ $aref } must be non-refs
            for (@{ $aref }) {
                if (ref) {
                    die "the new_check constructor recieved what was evaluated to be a list_check, but one of its elements was a ref!";
                }
            }
            $add_check_object->( $aref );

        }
    };

    my $process_1_elem = sub {
        my $elem = shift;
        my $ref = ref $elem;

        if ($ref eq 'ARRAY') {
            $process_aref->( $elem );

        } elsif ($ref eq '_check_object') {
            push @check_objects, $elem;

        } elsif (! $ref or $ref eq 'Regexp' or $ref eq 'CODE') {
            $add_check_object->( $elem );

        } else {
            die "the new_check constructor accepts only one scalar, aref, regex_ref, code_ref, or check object argument";

        }
    };


    # aref.
    if (ref $raw_checks eq 'ARRAY') {
        # []
        if (scalar @$raw_checks == 0) {
            die "the new_check constructor recieved an aref, but it was empty!";

        # [ ^ ]  -- just one element in the aref
        } elsif (scalar @$raw_checks == 1) {
            $process_1_elem->( $raw_checks->[0] );

        # [ ^,^ ]  -- either a list check or one check and an error msg
        } elsif (scalar @$raw_checks == 2) {
            if (ref $raw_checks->[0] eq '_check_object' or ref $raw_checks->[1] eq '_check_object') {
                $process_1_elem->( $raw_checks->[0] );
                $process_1_elem->( $raw_checks->[1] );

            } else {
                my $check_type_2nd_elem = eval { _classify_check_type( $raw_checks->[1] ) };

                # if 2nd elem is a check, so must the 1st be
                if ($check_type_2nd_elem) {
                    $process_1_elem->( $raw_checks->[0] );
                    $process_1_elem->( $raw_checks->[1] );

                # since the 2nd elem does not look like a check, either we
                # have a [check, err] list or a valid values aref with only 2 elems
                } else {
                    $process_1_elem->( $raw_checks );

                }
            }

        # [ ^,^,^... ]  -- more than 2 elements, ergo must have multiple checks or be one list_check
        } else {
            my $found_ref;
            for (@$raw_checks) {
                if (ref) {
                    $found_ref++;
                    last;
                }
            }

            if ($found_ref) {
                # process each elem as a check
                for (@$raw_checks) {
                    $process_1_elem->( $_ );
                }

            # simple list_check
            } else {
                $process_1_elem->( $raw_checks );

            }
        }

    # non-aref
    } else {
        $process_1_elem->( $raw_checks );

    }

    # return either an aref of check objects, or one check
    # object by itself if there was only one
    return $#check_objects ? [@check_objects] : $check_objects[0];
}

# private function, not a method
sub _classify_check_type {
    my $try = shift;

    if (ref $try eq 'CODE') {
        return 'custom_check';
    } elsif (ref $try eq 'ARRAY') {
        return 'list_check';
    } elsif (ref $try eq 'Regexp') {
        return 'regex_check';
    } elsif (!ref $try and $try =~ /\s*SELECT\s+/i) {
        return 'sql_check';
    } elsif (!ref $try) {
        if ($try =~/^\s*(lt|gt|le|ge|eq|ne|cmp|<=>|<=|>=|==|!=|<|>)\s*/) {
            return 'compare_check';
        }
        elsif
        (
            grep /^$try$/ => qw'
                                -r -w -x
                                -R -W -X
                                -o -O
                                -e -z
                                -s
                                -f -d
                                -l -S -p
                                -b -c
                                -u -g -k

                                -T -B
                                -M -A -C
                               '
        )
        {
            return 'filetest_check';
        }
    }

    die "'$try' is of an unrecognizable check type!"
}

# allow setting if individual parms, ala:
#    $ui->dbh( $dbh );
# or getting of individual parm values, ala:
#    print $ui->dbh;
sub AUTOLOAD {
    return if $AUTOLOAD =~ /::DESTROY$/;
    $AUTOLOAD =~ s/.*:://;  # trim the package name
    my $self = shift;

    if (exists $self->{$AUTOLOAD}) {
        if (@_) {
            if ($#_) { die "Only one value may passed for setting parm values!" }
            return $self->{$AUTOLOAD} = $_[0];
        } else {
            return $self->{$AUTOLOAD};
        }
    } else {
        die "\$self->$AUTOLOAD( @_ ) was called, yet no parameter named $AUTOLOAD currently exists!";
    }

}


sub get {
    # # multiple parms
    # $ui->get(
    #           [
    #               $parm_1_href,
    #               $parm_2_aref,
    #           ]
    #         );
    #
    # # only 1 parm
    # $ui->get(
    #               $parm_key_1    =>  $parm_val_1,
    #               $parm_key_2    =>  $parm_val_2,
    #         );
    my $self = shift;
    my @parms;

    if ($#_ == 0) {
        if (ref $_[0] eq 'ARRAY'){
            for (@{$_[0]}) {
                die "Invalid element of aref arg to get method: $_!" if (ref and ref !~ m'HASH|ARRAY');
                push @parms, $_;
            }
        } elsif (ref $_[0] eq 'HASH'){
            $parms[0] = $_[0];
        } else {
            die "invalid arg: $_[0]";
        }
    } else {
        $parms[0] = [ @_ ];
    }

    my @return;
    for (@parms) {
        my $parm = $self->process_args( $_ );
        bless $parm => ref($self);

        unless ($parm->{interact}) {
            die 'Interact mode is off, yet there is no default set for parm: ' .
                (defined $parm->{name} ? $parm->{name} : '[no name recorded]') .
                '!'
                unless defined $parm->{default};
            my $default = (ref $parm->{default} eq 'ARRAY') ? $parm->{default} : [$parm->{default}];
            if (defined $parm->{type} and $parm->{type} eq 'date') {
                $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$default;
            }
            push @return, ($#{$default}) ? $default : $default->[0];
            next;
        }

        my $OUT = $parm->{FH_OUT};
        my $IN  = $parm->{FH_IN};

        my $delimiter;
        my $delimiter_pattern;
        my $delimiter_pattern_split;
        my $delimiter_desc = '';
        if (defined $parm->{delimiter}) {
            $delimiter = $parm->{delimiter};
            $delimiter_pattern = quotemeta $delimiter;
            $delimiter_pattern_split = $delimiter_pattern;

            if ($parm->{delimiter_spacing}) {
                $delimiter_pattern_split = '\s*' . $delimiter_pattern_split . '\s*'
            }

            for ($delimiter_pattern, $delimiter_pattern_split) {
                $_ = qr/$_/;
            }

            if      ($delimiter eq ',') {
                $delimiter_desc = 'commas';
            } else {
                $delimiter_desc = $delimiter;
            }
        }

        print $OUT $parm->{menu} if $parm->{menu};

        # $w_ vars contain word strings to be combined later into appropriate prompts
        my $w_default = '';
        my $w_value_values = '';

        if (defined $parm->{msg}) {
            if ($parm->{msg} ne '') {
                my $msg = $parm->{msg};
                $msg =~ s/^\n+//;
                print $OUT  ("\n" x $parm->{msg_newline}),
                            autoformat
                            (
                                $parm->interpolate
                                (
                                    $parm->{msg},
                                    defined $parm->{default}
                                      ? $parm->{default}
                                      : ()
                                ),
                                $parm->_get_autoformat_args({left=>$parm->{msg_indent}})
                            );
            }
        } else {
            if (! $parm->{succinct}) {
                # This is the default message format
                #
                # [Name: ][The default value/values is/are LIST_HERE.  ]Enter a value[ or list of values delimited with DELIMITER_DESC_HERE][ (use the word NULL to indicate a null value/any null values)].

                # set up words
                my $name = (defined $parm->{name}) ? "$parm->{name}: " : '';

                my $enter = 'Enter a value';

                my $default = '';
                my $w_is_are = 'is';
                $w_value_values = 'value';
                if (defined $parm->{default} and $parm->{default} ne '') {
                    $enter = 'enter a value';

                    if (defined $delimiter && (ref $parm->{default} eq 'ARRAY')) {
                        my @defaults;
                        if (defined $parm->{type} and $parm->{type} eq 'date') {
                            push @defaults, UnixDate("epoch $_",$parm->{date_format_display}) for @{ $parm->{default} };
                        } else {
                            push @defaults, @{ $parm->{default} };
                        }
                        if ($#{ $parm->{default} }) {
                            $w_value_values = 'values';
                            $w_is_are = 'are';
                            $w_default = join "$delimiter " => @defaults;
                        } else {
                            $w_default = $parm->{default}->[0];
                        }
                    } else {
                        if (defined $parm->{type} and $parm->{type} eq 'date') {
                            $w_default = UnixDate('epoch ' . $parm->{default}, $parm->{date_format_display} );
                        } else {
                            $w_default = $parm->{default};
                        }
                    }

                    $default =  "The default $w_value_values $w_is_are $w_default.  Press ENTER to accept the default, or ";
                }

                my $or_list_of_values = '';

                my $use_NULL_use_NULLs = ($parm->{allow_null})
                                       ? ' (use the word NULL to indicate a null value)'
                                       : '';

                if (defined $delimiter) {
                  $or_list_of_values = " or list of values delimited with $delimiter_desc";
                  $use_NULL_use_NULLs = ' (use the word NULL to indicate any null values)' if ($parm->{allow_null});
                }

                my $msg = $name . $default . $enter . $or_list_of_values . $use_NULL_use_NULLs . '.';

                print $OUT ("\n" x $parm->{msg_newline}),
                           autoformat( $msg, $parm->_get_autoformat_args({left=>$parm->{msg_indent}}) );
            } else {
                print $OUT ("\n" x $parm->{msg_newline});
                print $OUT autoformat( 
                                       (
                                         defined $parm->{name}
                                         ? $parm->{name}
                                         : ''
                                       ),
                                       $parm->_get_autoformat_args({left=>$parm->{msg_indent}})
                                     );

                # if a default was specified
                if (defined $parm->{default}) {
                    # if msg is just the default
                    my $defaults = $parm->parameters(default => 1);
                    if ($parm->{prompt} eq $defaults->{prompt}) {
                        # make nice, succinct prompt: [default_value]>
                        $parm->{prompt} = '[' . $parm->{default} . ']> ';
                    }
                }
            }
        }

        my $ok = 0;
        my $i = 0;
        my $return;

        PROMPT:
        until ($ok) {
            $i++;
            if ($parm->{maxtries} and $i > $parm->{maxtries}) {
                die "You have exceeded the maximum number of allowable tries\n";
            }

            my $prompt;
            my $endspace = '';

            # autoformat kills any trailing space from the prompts, so this will recapture it
            my $get_endspace = sub {
                if ( $_[0] =~ /(\s+)$/ ) { $endspace = $1 }
            };

            if ($i > 1) {
                $prompt = (defined $parm->{re_prompt}) ? $parm->{re_prompt} : $parm->{prompt};
                $get_endspace->($prompt);
                $prompt = autoformat( $prompt, $parm->_get_autoformat_args({left=>$parm->{prompt_indent}}) );
            } else {
                $get_endspace->( $parm->{prompt} );
                $prompt = autoformat( $parm->{prompt}, $parm->_get_autoformat_args({left=>$parm->{prompt_indent}}) );
            }
            chomp $prompt;
            $prompt .= $endspace;

            # allow for invisible user input
            ReadMode( $parm->{ReadMode}, $IN ) if (defined $parm->{ReadMode});

            alarm $parm->{timeout}  unless ($^O eq 'MSWin32');

            my $stdin;
            print $OUT $prompt;
            $stdin = <$IN>;
            chomp $stdin;

            alarm 0 unless ($^O eq 'MSWin32');

            # restore original console settings
            if (defined $parm->{ReadMode}) {
                ReadMode(0, $IN );
                print $OUT "\n" if ($parm->{ReadMode} == 2);
            }

            if ($stdin eq '') {
                next PROMPT unless (defined $parm->{default});
            } else {
                # split input into an aref if apropriate
                if (defined $delimiter and $stdin =~ /$delimiter_pattern/) {
                    if ($parm->{delimiter_spacing}) {
                        # get rid of any whitespace at front of string
                        $stdin =~ s/^\s*//;
                        # get rid of any delimiter and whitespace at beginning of string
                        $stdin =~ s/^$delimiter_pattern\s*//;
                    }
                    $stdin = [ split /$delimiter_pattern_split/ => $stdin ];
                    if (defined $parm->{min_elem}) {
                        if (scalar @$stdin < $parm->{min_elem}) {
                            my $elements = $parm->{min_elem} > 1 ? 'elements' : 'element';
                            print $OUT autoformat(
                                                    "You must specify at least $parm->{min_elem} $elements in your '$delimiter' delimited list",
                                                    $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                                                 );
                            next PROMPT;
                        }
                    }
                    if (defined $parm->{max_elem}) {
                        if (scalar @$stdin > $parm->{max_elem}) {
                            my $elements = $parm->{max_elem} > 1 ? 'elements' : 'element';
                            print $OUT autoformat(
                                                    "You may specify at most $parm->{max_elem} $elements in your '$delimiter' delimited list",
                                                    $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                                                 );
                            next PROMPT;
                        }
                    }
                    if (defined $parm->{unique_elem} and $parm->{unique_elem}) {
                        my %saw;
                        if ( scalar grep(!$saw{$_}++, @$stdin) != scalar @$stdin ) {
                            print $OUT autoformat(
                                                    "Each element of the '$delimiter' delimited list must be unique.\n",
                                                    $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                                                 );

                            next PROMPT;
                        }
                    }
                } else {
                    # put it into an aref anyway, for convenient processing
                    $stdin = [ $stdin ];
                }

                if (defined $parm->{case}) {
                    if ($parm->{case} eq 'uc') {
                        $_ = uc $_ for @$stdin;
                    } elsif ($parm->{case} eq 'lc') {
                        $_ = lc $_ for @$stdin;
                    } elsif ($parm->{case} eq 'ucfirst') {
                        $_ = ucfirst $_ for @$stdin;
                    } else {
                        die "Invalid case parameter: $parm->{case}"
                    }
                }

                # if date(s), convert to unix timevalue
                if (defined $parm->{type} and $parm->{type} eq 'date') {
                    for (@$stdin) {
                        unless (/^NULL$/i) {
                            my $time = UnixDate($parm->{date_preprocess}->($_),"%s");
                            if (defined $time) {
                                $_ = $time;
                            } else {
                                $_ = $parm->{echo_quote} . $_ . $parm->{echo_quote} if ($parm->{echo_quote});
                                print $OUT autoformat("$_ is not a valid date",$parm->_get_autoformat_args({left=>$parm->{prompt_indent}}));
                                next PROMPT;
                            }
                        }
                    }
                }
            }

            my $confirm = sub {
                my $prompt = shift;
                chomp $prompt;

                my $yn;
                print $OUT $prompt;
                $yn = <$IN>;
                chomp $yn;

                $yn = 'Y' if ($yn eq '');
                while ($yn !~ /[YyNn]/) {
                    print $OUT "    (Y|n) ";
                    $yn = <$IN>;
                    chomp $yn;
                }

                return ($yn =~ /y/i) ? 1 : 0;
            };

            if (defined $parm->{confirm} and $parm->{confirm}) {
                if (!ref $stdin and $stdin eq '') {
                    next PROMPT unless (
                        $confirm->(
                            autoformat(
                                (
                                    'You accepted the default'
                                    . ($w_value_values ? " $w_value_values" : '')
                                    . ($w_default ? ": $w_default" : '')
                                    . '.  Is this correct? (Y|n) '
                                ),
                                $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                            )
                        )
                    );
                    # $return will be set to the default below...
                } else {
                    my @confirm;
                    if (defined $parm->{type} and $parm->{type} eq 'date') {
                        push @confirm, UnixDate("epoch $_", $parm->{date_format_display}) for (@$stdin);
                    } else {
                        @confirm = @$stdin;
                    }

                    if ($parm->{echo_quote}) {
                        $_ = $parm->{echo_quote} . $_ . $parm->{echo_quote} for @confirm;
                    }

                    next PROMPT unless (
                        $confirm->(
                            autoformat(
                                "You entered: " .
                                (
                                (defined $delimiter) ? join("$delimiter " => @confirm) : $confirm[0]
                                ) .
                                ".  Is this correct? (Y|n) ",
                                $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                            )
                        )
                    );
                }
            }

            # if user entered anything, it's in an aref by now
            if (ref $stdin) {
                if ($parm->{check}) {
                    my @validate_args = ($stdin);
                    if (defined $parm->{type} and $parm->{type} eq 'date') {
                        push @validate_args, (date_format_return => '%s');
                    }
                    $return = $parm->validate( @validate_args );
                    next PROMPT unless defined $return;
                }
            # user didn't enter anything, so let's see about using the default
            } else {
                if ($parm->{check_default}) {
                    my @validate_args = ($parm->{default});
                    if (defined $parm->{type} and $parm->{type} eq 'date') {
                        push @validate_args, (date_format_return => '%s');
                    }
                    $return = $parm->validate( @validate_args );
                    next PROMPT unless defined $return;
                } else {
                    $return = $parm->{default};
                }
            }

            # Catch anything that fell through [I don't think this is necessary any more...]
            $return = $stdin unless defined $return;

            $return = [ $return ] unless (ref $return eq 'ARRAY');

            $ok = 1;
        }

        $return = $parm->translate( $return );

        if ($parm->{echo}) {
            my @echo;
            if (defined $parm->{type} and $parm->{type} eq 'date') {
                push @echo, UnixDate("epoch $_", $parm->{date_format_display}) for (@$return);
            } else {
                @echo = @$return;
            }

            if ($parm->{echo_quote}) {
                $_ = $parm->{echo_quote} . $_ . $parm->{echo_quote} for @echo;
            }
            
            print $OUT autoformat( 
                                   (
                                     defined $parm->{name}
                                     ? $parm->{name}
                                     : 'parm'
                                   ) .
                                   ' set to: ' . 
                                   (
                                     defined $parm->{delimiter}
                                     ? join $parm->{delimiter}, @echo
                                     : $echo[0]
                                   ),
                                   $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                                 );
        }

        if (defined $parm->{type} and $parm->{type} eq 'date') {
            $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$return;
        }

        # calling program determines whether an aref or scalar is returned via the delimiter parm
        push @return, ((defined $delimiter) ? $return : $return->[0]);
    }

    return $#parms ? @return : $return[0];

}

sub validate {
    my $self = shift;
    my $data = shift;

    # While the get method will only call validate with data, another
    # program might want to validate data that it does not realize is
    # undefined.  In that case we'll take a shortcut and just return 0.
    return 0 unless defined $data;

    my $parm;
    my $return;

    if (exists $self->{check}) {
        $parm = $self;

    # if no $self->{check} exists, then this method was called by the
    # invocant script
    } else {
        # demand a check parm in the passed in parms
        unless (grep /^check$/ => @_) {
            die "The validate method was invoked without a check parm either in \$self or in the passed in parms!";
        }
        $parm = $self->process_args( @_ );
        bless $parm => ref($self);
    }

    CONFIRM_CHECK_OBJ:
    # for each check object
    for
    (
        ref $parm->{check} eq 'ARRAY'
        ? @{ $parm->{check} }
        :  ( $parm->{check} )
    )
    {
        unless (ref eq '_check_object') {
            $parm->{check} = $parm->new_check( $parm->{check} );
            last CONFIRM_CHECK_OBJ;
        }
    }


    # $parm->{check} is either an aref of multiple check
    # objects, or just one check object by itself
    for
    (
        ref $parm->{check} eq 'ARRAY'
        ? @{ $parm->{check} }
        :  ( $parm->{check} )
    )
    {
        my $check_type = $_->{check_type};
        # ensure there exists a method named the same as check_type
        unless ($parm->can( $check_type )) {
            die "You tried to invoke a check named $check_type, but no method of that name exists.  Did you forget to code the method?";
        }

        # use the method named the same as check_type, passing our
        # current check_type and check object in as a key=>value  pair
        $return = $parm->$check_type(
            $data,
            $check_type => $_,
            @_,
        );
        last unless defined $return;
    }

    return $return;
}

sub translate {
    my $self = shift;
    my $data = shift;

    return $data unless $self->{translate};

    unless (ref $self->{translate} eq 'ARRAY') {
        die "the value for the translate parameter must be an aref";
    }

    for my $data (@$data) {
        for (@{ $self->{translate} }) {
            # ensure translate parm has the requisite two elements
            unless (ref eq 'ARRAY' and scalar @$_ == 2) {
                die "each translate parameter must be an aref with exactly 2 elements";
            }

            # instantiate a new obj with $_->[0] as the check
            my $parm = $self->process_args( check => $_->[0] );
            bless $parm => ref($self);

            if ($parm->validate( $data )) {
                if ( $data eq 'NULL' ) {
                    # At invocant request, check methods will sometimes validate a
                    # data string of 'NULL' even though that string really doesn't
                    # match the privided check criteria.
                    if (defined $parm->{allow_null} and $parm->{allow_null}) {

                        # unless $_->[0] explicitely names 'NULL' we
                        # will move on to the next $data instead of
                        # translating this one
                        if ( ref $_->[0] eq 'ARRAY') {
                            next unless grep /NULL/ => @{$_->[0]};

                        } elsif (!ref $_->[0]) {
                            next unless $_->[0] =~ /\s*==\s*NULL$/;

                        } else {
                            next;

                        }
                    }
                }

                # translate $data
                $data = $_->[1];
            }
        }
    }

    return $data;
}

sub custom_check {
    my $self = shift;
    my $data = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    unless (ref $data eq 'ARRAY') {
        die "Data passed to _custom_check must be aref or scalar" if (ref $data);
        $data = [ $data ];
    }

    my $qr_NULL = (defined $parm->{allow_null} and $parm->{allow_null})
                ? qr/^NULL$/i
                : '';

    my $check = sub {
        my $try = shift;
        return 1 if ($qr_NULL and $try =~ /$qr_NULL/);
        return 1 if $parm->{custom_check}->{check}->($try);
        if (defined $parm->{custom_check}->{err_msg}) {
            print $OUT
            (
                autoformat(
                            $parm->interpolate($parm->{custom_check}->{err_msg},$try,$parm->{custom_check}->{check}),
                            $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                          )
            );
        }
        return 0;
    };

    for (@$data) {
        return undef unless $check->( $_ );
    }

    return $data;
}

sub filetest_check {
    my $self = shift;
    my $data = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    unless (defined $parm->{filetest_check}) {
        die "filetest_check was invoked, but no filetest_check-specific information was found!";
    }

    unless (ref $data eq 'ARRAY') {
        die "Data passes to filetest_check must be aref or scalar" if (ref $data);
        $data = [ $data ];
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        die "filetest_check is not a valid option in conjunction with a parm type of 'date'!";
    }

    my $qr_NULL = (defined $parm->{allow_null} and $parm->{allow_null})
                ? qr/^NULL$/i
                : '';

    my $check = sub {
        my $try = shift;
        return 1 if ($qr_NULL and $try =~ /$qr_NULL/);

        if ($parm->{filetest_check}->{check} eq '-r') { return 1 if -r $try }
        if ($parm->{filetest_check}->{check} eq '-w') { return 1 if -w $try }
        if ($parm->{filetest_check}->{check} eq '-x') { return 1 if -x $try }
        if ($parm->{filetest_check}->{check} eq '-R') { return 1 if -R $try }
        if ($parm->{filetest_check}->{check} eq '-W') { return 1 if -W $try }
        if ($parm->{filetest_check}->{check} eq '-X') { return 1 if -X $try }
        if ($parm->{filetest_check}->{check} eq '-o') { return 1 if -o $try }
        if ($parm->{filetest_check}->{check} eq '-O') { return 1 if -O $try }
        if ($parm->{filetest_check}->{check} eq '-e') { return 1 if -e $try }
        if ($parm->{filetest_check}->{check} eq '-z') { return 1 if -z $try }
        if ($parm->{filetest_check}->{check} eq '-s') { return 1 if -s $try }
        if ($parm->{filetest_check}->{check} eq '-f') { return 1 if -f $try }
        if ($parm->{filetest_check}->{check} eq '-d') { return 1 if -d $try }
        if ($parm->{filetest_check}->{check} eq '-l') { return 1 if -l $try }
        if ($parm->{filetest_check}->{check} eq '-S') { return 1 if -S $try }
        if ($parm->{filetest_check}->{check} eq '-p') { return 1 if -p $try }
        if ($parm->{filetest_check}->{check} eq '-b') { return 1 if -b $try }
        if ($parm->{filetest_check}->{check} eq '-c') { return 1 if -c $try }
        if ($parm->{filetest_check}->{check} eq '-u') { return 1 if -u $try }
        if ($parm->{filetest_check}->{check} eq '-g') { return 1 if -g $try }
        if ($parm->{filetest_check}->{check} eq '-k') { return 1 if -k $try }
        if ($parm->{filetest_check}->{check} eq '-T') { return 1 if -T $try }
        if ($parm->{filetest_check}->{check} eq '-B') { return 1 if -B $try }
        if ($parm->{filetest_check}->{check} eq '-M') { return 1 if -M $try }
        if ($parm->{filetest_check}->{check} eq '-A') { return 1 if -A $try }
        if ($parm->{filetest_check}->{check} eq '-C') { return 1 if -C $try }

        if (defined $parm->{filetest_check}->{err_msg}) {
            print $OUT
            (
                autoformat(
                            $parm->interpolate($parm->{filetest_check}->{err_msg},$try,$parm->{filetest_check}->{check}),
                            $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                          )
            );
        }
        return 0;
    };

    for (@$data) {
        return undef unless $check->( $_ );
    }

    return $data;
}

sub regex_check {
    my $self = shift;
    my $data = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    unless (defined $parm->{regex_check}) {
        die "regex_check was invoked, but no regex_check-specific information was found!";
    }

    unless (ref $data eq 'ARRAY') {
        die "Data passes to regex_check must be aref or scalar" if (ref $data);
        $data = [ $data ];
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        die "regex_check is not a valid option in conjunction with a parm type of 'date'!";
    }

    my $qr_NULL = (defined $parm->{allow_null} and $parm->{allow_null})
                ? qr/^NULL$/i
                : '';

    my $check = sub {
        my $try = shift;
        return 1 if ($qr_NULL and $try =~ /$qr_NULL/);
        return 1 if ($try =~ /$parm->{regex_check}->{check}/);
        if (defined $parm->{regex_check}->{err_msg}) {
            print $OUT
            (
                autoformat(
                            $parm->interpolate($parm->{regex_check}->{err_msg},$try,$parm->{regex_check}->{check}),
                            $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                          )
            );
        }
        return 0;
    };

    for (@$data) {
        return undef unless $check->( $_ );
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$data;
    }

    return $data;
}


sub sql_check {
    my $self = shift;

    my $data = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    unless (defined $parm->{sql_check}) {
        die "sql_check was invoked, but no sql_check-specific information was found!";
    }

    unless (ref $data eq 'ARRAY') {
        die "First arg to sql_check must be aref or scalar" if (ref $data);
        $data = [ $data ];
    }

    unless ($parm->{dbh}) {
        die "No database handle was passed to sql_check!";
    }

    # get an aref of values from the database
    my $list = $parm->{dbh}->selectcol_arrayref( $parm->{sql_check}->{check} )
        or die "This SQL statement did not return any rows: $parm->{sql_check}->{check}";

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        for (@$list) {
            my $epoch_seconds = 'epoch ' . UnixDate($parm->{date_preprocess}->($_),'%s')
                or die "Could not recognize $_ as a date!";
            $_ = $epoch_seconds;
        }
    }

    # create a new list_check
    my $new_check = $parm->new_check(
                                        [
                                            $list,
                                            $parm->{sql_check}->{err_msg}
                                              ? $parm->{sql_check}->{err_msg}
                                              : ()
                                        ]
                                    );

    # The check parm of the invocant of the validate method (which in
    # turn invoked this sql_check method) will be changed from a
    # sql_check into a list_check.  In the case where that invocant of
    # the validate method was the get method, for example, the returned
    # values from this sql_check will thus be preserved until the get
    # method finishes.
    for
    (
        ref $self->{check} eq 'ARRAY'
        ? @{ $self->{check} }
        :  ( $self->{check} )
    )
    {
        if
        (
            $_->{check_type} eq 'sql_check'
              and
            $_->{check} eq $parm->{sql_check}->{check}
              and
            (
                !exists $parm->{sql_check}->{err_msg}
                  or
                !exists $_->{err_msg}
                  or
                $_->{err_msg} eq $parm->{sql_check}->{err_msg}
            )
        )
        {
            $_ = $new_check;
            last;
        }
    }

    # now we use the list_check method with our new check object
    return $parm->list_check( $data, $new_check->{check_type} => $new_check );

}

sub list_check {
    my $self = shift;
    my $data = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);
    my $OUT = $parm->{FH_OUT};

    unless (defined $parm->{list_check}) {
        die "list_check was invoked, but no list_check-specific information was found!";
    }

    unless (ref $data eq 'ARRAY') {
        die "First arg to list_check must be aref or scalar" if (ref $data);
        $data = [ $data ];
    }

    # date preprocessing
    if (defined $parm->{type} and $parm->{type} eq 'date') {
        for (@{ $parm->{list_check}->{check} }) {
            if (/^\s*epoch\s+(\-?\d+)\s*$/io) {
                s/.*/$1/;
            } else {
                my $epoch_seconds = UnixDate($parm->{date_preprocess}->($_),'%s')
                    or die "Could not recognize $_ as a date!";
                $_ = $epoch_seconds;
            }
        }
    }
    my $qr_NULL = (defined $parm->{allow_null} and $parm->{allow_null})
                ? qr/^NULL$/i
                : '';

    for my $val (@$data) {
        unless ($qr_NULL and $val =~ /$qr_NULL/) {
            unless (grep /^$val$/ => @{ $parm->{list_check}->{check} }) {
                print $OUT (
                    autoformat(
                        $parm->interpolate(
                            $parm->{list_check}->{err_msg},
                            $val,
                            join(
                                (
                                    (defined $parm->{delimiter})
                                    ? "$parm->{delimiter} "
                                    : ', '
                                ),
                                (
                                    (defined $parm->{type} and $parm->{type} eq 'date')
                                    ? map { UnixDate("epoch $_",$parm->{date_format_display}) } @{ $parm->{list_check}->{check} }
                                    : @{ $parm->{list_check}->{check} }
                                )
                            )
                        ),
                        $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})
                    )
                ) if (defined $parm->{list_check}->{err_msg});
                return undef;
            }
        }
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$data;
    }
    return $data;
}

sub compare_check {
    my $self = shift;
    my $data = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    unless (defined $parm->{compare_check}) {
        die "compare_check was invoked, but no compare_check-specific information was found!";
    }

    unless (ref $data eq 'ARRAY') {
        die "First arg to compare_check must be aref or scalar" if (ref $data);
        $data = [ $data ];
    }

    my $qr_cmp = qr/^(\s*(lt|gt|le|ge|eq|ne|cmp|<=>|<=|>=|==|!=|<|>)\s*)/;
    my $qr_numeric = qr/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;  # from perlfaq

    my $cmp_val = $parm->{compare_check}->{check};
    # match and cut comparison operator from front of string
    $cmp_val =~ s/$qr_cmp//;
    # capture matched comparison operator
    my $cmp = $2;

    if ($cmp eq '<=>' or $cmp eq 'cmp') {
        die "$cmp is not an unsupported comparison operator for the compare_check method!";
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        my $epoch_seconds = UnixDate($parm->{date_preprocess}->($cmp_val),'%s')
            or die "Could not recognize comparison value $cmp_val as a date!";
        $cmp_val = $epoch_seconds;
        # as we're keeping track of this comparison check for possible use by an error message, let's conform
        # it to the desired formatting.
        $parm->{compare_check}->{check} = "$cmp " . UnixDate("epoch $epoch_seconds", $parm->{date_format_display});
    }

    for my $val (@$data) {
        if ($cmp =~ /(<|>|<=|>=|==|!=)/) {
            if ($val =~ /$qr_numeric/) {
                if    ($cmp eq '<'  ) { unless ($val <   $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
                elsif ($cmp eq '>'  ) { unless ($val >   $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
                elsif ($cmp eq '<=' ) { unless ($val <=  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
                elsif ($cmp eq '>=' ) { unless ($val >=  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
                elsif ($cmp eq '==' ) { unless ($val ==  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
                elsif ($cmp eq '!=' ) { unless ($val !=  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
                else                  { die "Unknown comparison operator: $cmp" }
            } else {
                print $OUT ( autoformat("'$val' is not numeric.", $parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) );
                return undef;
            }
        } else {
            if    ($cmp eq 'lt' ) { unless ($val lt  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
            elsif ($cmp eq 'gt' ) { unless ($val gt  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
            elsif ($cmp eq 'le' ) { unless ($val le  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
            elsif ($cmp eq 'ge' ) { unless ($val ge  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
            elsif ($cmp eq 'eq' ) { unless ($val eq  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
            elsif ($cmp eq 'ne' ) { unless ($val ne  $cmp_val) { print $OUT ( autoformat($parm->interpolate($parm->{compare_check}->{err_msg},$val,$parm->{compare_check}->{check}),$parm->_get_autoformat_args({left=>$parm->{prompt_indent}})) ) if ($parm->{compare_check}->{err_msg}); return undef; } }
            else                  { die "Unknown comparison operator: $cmp" }
        }
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$data;
    }

    return $data;
}

sub star_obscure {
    my $self = shift;
    return @_ unless (defined $self->{ReadMode} and $self->{ReadMode} == 2);

    my $aref = ref $_[0]
               ? $_[0]
               : [ $_[0] ];

    for (@$aref) {
        if (length() < 6) {
            $_ = '******';
        } else {
            s/./*/g;
        }
    }

    return ref $_[0] ? $aref : $aref->[0];
}


sub format_for_display {
    my $self = shift;
    my $aref = ref $_[0] eq 'ARRAY'
               ? $_[0]
               : [ $_[0] ];
    my $date_format = (defined $self->{type} and $self->{type} eq 'date')
                      ? $self->{date_format_display}
                      : '';

    for (@$aref) {
        if ($date_format and /$qr_epoch/) {
            $_ = UnixDate("epoch $_",$date_format);
        }
    }
    return join
    (
        defined $self->{delimiter}
          ? "$self->{delimiter} "
          : ', '
        =>
        @$aref
    );
}

sub interpolate {
    my $self = shift;
    my $picture = shift;

    # interpolate the contents of @_ into $picture
    my $qr_sprintf_s = qr/\%s/;
    if ( $picture =~ /$qr_sprintf_s/ ) {
        if ($self->{echo_quote}) {
            $picture =~ s/$qr_sprintf_s/$self->{echo_quote}%s$self->{echo_quote}/;
        }
        return sprintf($picture, map {$self->format_for_display($_)} @_);
    } else {
        return $picture;
    }
}

sub set_TZ ($) {
    my $time_zone = shift;

    # Date::Manip cannot determine the time zone under windows, so in the interest
    # of portability we'll help out.
    unless (defined $main::TZ) {
        if (defined $time_zone) {
            $main::TZ = $time_zone;
        } else {
            # the following code (to determine a timezone for Date::Manip)
            # is attributed to a usenet post by Larry Rosler
            my ($l_min, $l_hour, $l_year, $l_yday) = (localtime $^T)[1, 2, 5, 7];
            my ($g_min, $g_hour, $g_year, $g_yday) = (   gmtime $^T)[1, 2, 5, 7];
            my $tzval = ($l_min - $g_min)/60 + $l_hour - $g_hour + 24 * ($l_year <=> $g_year || $l_yday <=> $g_yday);
            $tzval = sprintf( "%2.2d00", $tzval);
            $tzval = '+' . $tzval unless ($tzval =~ /^\-/);

            # Versions of Date::Manip prior to 5.41 don't understand hour offset TZ values
            if (DateManipVersion() <= 5.4) {
                # This is a cheesy cross ref between hour offsets (gotten above)
                # and alpha TZ codes.  This is *really* suboptimal because of course
                # more than one alpha TZ code corresponds with each hour offset.
                # You can avoid this by passing in a TZ instead.
                my %tz = qw( -1200 IDLW -1100 NT -1000 HST -0900 AKST -0800 PST -0700 MST -0600 CST -0500 EST -0400 AST -0300 ADT -0200 AT -0200 SAST -0100 WAT +0000 UTC +0100 CET +0200 EET +0300 MSK +0400 ZP4 +0500 ZP5 +0600 ZP6 +0800 CCT +0900 JST +1000 EAST +1100 EADT +1200 NZST +1300 NZDT );
                $tzval = $tz{$tzval} or die "*Really* unexpected error";
            }
            $main::TZ = $tzval;
        }
    }
}

sub _get_autoformat_args {
    my $self = shift;
    my $addl_parm_href = shift || {};

    #put the shared args into $return
    my $return = {};
    for (keys %{$self->{shared_autoformat_args}}) {
        $return->{$_} = $self->{shared_autoformat_args}{$_};
    }

    # shared_autoformat_args override everything else
    for (keys %{ $addl_parm_href }) {
        $return->{$_} = $addl_parm_href->{$_} unless defined $return->{$_};
    }

    return $return;
}

1;
__END__

=head1 AUTHOR

Term::Interact by Phil R Lawrence.

=head1 SUPPORT

Support is available by emailing the author directly:
  prl ~AT~ cpan ~DOT~ org

=head1 COPYRIGHT

The Term::Interact module is Copyright (c) 2002 Phil R Lawrence.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 NOTE

This module was developed while I was in the employ of Lehigh University.  They kindly allowed me to have ownership of the work with the understanding that I would release it to open source.  :-)

=head1 SEE ALSO

Text::Autoformat, Term::ReadKey, Date::Manip

=cut



FUTURE development:

1.  Fancy logging:  log => *FH_LOG
2.  Instantiate and default all parms with the new() method
    Discard any non-applicable passed-in parms
