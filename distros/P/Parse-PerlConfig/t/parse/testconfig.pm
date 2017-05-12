# information about the various configuration files
# $Id: testconfig.pm,v 1.4 2000/10/19 08:05:11 mfowler Exp $

# This module is here to make test script maintenance easier.  Each and
# every test script needn't know about the details of a configuration file;
# instead they ask a parse::testconfig object about various things.


package parse::testconfig;


use Text::Wrap;
use Cwd qw(getcwd);
use strict;
use vars qw($ok_object @ISA @EXPORT_OK %test_conf %parsed);


require Exporter;
@EXPORT_OK = qw(ok);
@ISA = qw(Exporter);


$Text::Wrap::columns = 80;


%test_conf = (
    'lex-test.conf' => {
        Lexicals => {
            Config => 'lexical_config',
        },

        Symbols => {},
    },

    'test.conf' => {
        Lexicals        =>      {
            Config          =>      'lexical_config',
        },

        Symbols         =>      {
            'lexical_config'        =>  [qw(HASH)],
            'success'               =>  [qw(SCALAR)],

            's'             =>  [qw(SCALAR)],
            'a'             =>  [qw(ARRAY)],
            'h'             =>  [qw(HASH)],
            'f'             =>  [qw(CODE)],
            'i'             =>  [qw(IO)],
            's_a'           =>  [qw(SCALAR ARRAY)],
            's_h'           =>  [qw(SCALAR HASH)],
            's_f'           =>  [qw(SCALAR CODE)],
            's_i'           =>  [qw(SCALAR IO)],
            'a_h'           =>  [qw(ARRAY HASH)],
            'a_f'           =>  [qw(ARRAY CODE)],
            'a_i'           =>  [qw(ARRAY IO)],
            'h_f'           =>  [qw(HASH CODE)],
            'h_i'           =>  [qw(HASH IO)],
            'f_i'           =>  [qw(CODE IO)],
            's_a_h'         =>  [qw(SCALAR ARRAY HASH)],
            's_a_f'         =>  [qw(SCALAR ARRAY CODE)],
            's_a_i'         =>  [qw(SCALAR ARRAY IO)],
            's_h_f'         =>  [qw(SCALAR HASH CODE)],
            's_h_i'         =>  [qw(SCALAR HASH IO)],
            's_f_i'         =>  [qw(SCALAR CODE IO)],
            'a_h_f'         =>  [qw(ARRAY HASH CODE)],
            'a_h_i'         =>  [qw(ARRAY HASH IO)],
            'a_f_i'         =>  [qw(ARRAY CODE IO)],
            'h_f_i'         =>  [qw(HASH CODE IO)],
            's_a_h_f'       =>  [qw(SCALAR ARRAY HASH CODE)],
            's_a_h_i'       =>  [qw(SCALAR ARRAY HASH IO)],
            's_a_f_i'       =>  [qw(SCALAR ARRAY CODE IO)],
            's_h_f_i'       =>  [qw(SCALAR HASH CODE IO)],
            'a_h_f_i'       =>  [qw(ARRAY HASH CODE IO)],
            's_a_h_f_i'     =>  [qw(SCALAR ARRAY HASH CODE IO)],
        }
    },
);



# usage: class->new <configuration file>
sub new {
    my($class, $conf) = (shift, shift);
    $class = ref($class) || $class;

    die("Unknown configuration file \"$conf\".\n")
        unless defined($test_conf{$conf});

    my $obj = bless({ %{$test_conf{$conf}} }, $class);


    unless (defined $$obj{File_Path}) {
        my $cwd         =  getcwd();
        my $filename    =  $conf;

        my $file_path;
        if ($cwd =~ m|/+t/*$|) {
            $file_path = "$cwd/parse/$filename";
        } else {
            $file_path = "$cwd/t/parse/$filename";
        }


        $$obj{File_Path} = $file_path;
    }


    $obj->{Test_Number} = 1;

    return $obj;
}



sub file_path { shift->{File_Path} }



# usage: obj->verify_parsed [<parsed config hashref>]
sub verify_parsed {
    my $self    = shift;
    my %symbols = %{$self->{Symbols}};

    my $parsed;
    if (@_ >= 2) {
        my %args = @_;
        $parsed  = $args{'Parsed'} || undef;
        %symbols = map { $_, $symbols{$_} } @{ $args{'Symbols'} };

    } else {
        $parsed = shift;
    }


    unless (defined $parsed) {
        # 1     - the symbol count check
        # 1     - the check for extraneous symbols
        return 1 + 1 + keys(%symbols);
    }


    $self->ok(
        keys(%$parsed) == keys(%symbols),
        keys(%$parsed) . ' symbols found, ' . keys(%symbols) .
        ' expected'
    );

    while (my($sym, $things) = each(%symbols)) {
        if (exists $$parsed{$sym}) {
            $self->ok(1, "symbol $sym exists");
            delete($symbols{$sym});
        } else {
            $self->ok(0, "symbol $sym doesn't exist");
        }
    }

    $self->ok(
        !keys(%symbols),
        scalar(keys %symbols) . ' extraneous symbols'
    );


    return;
}



# usage: obj->verify_parsed_default_lexicals [<parsed config hashref>]
sub verify_parsed_default_lexicals {
    my($self, $parsed) = (shift, shift);


    return 2 + $self->verify_lexicals_config() unless defined($parsed);


    my $lex_conf = $self->verify_lexicals_config($parsed);


    $self->ok(
        $$lex_conf{Filename} eq $self->{File_Path},
        'config lexical filename key matches file path'
    );

    $self->ok(
        defined($$lex_conf{Namespace}),
        'config lexical namespace key defined'
    );
}



# usage: obj->verify_lexicals_config [<parsed config hashref>]
sub verify_lexicals_config {
    my($self, $parsed) = (shift, shift);


    return 2 unless defined($parsed);


    my $lex_conf;
    $self->ok(
        defined($lex_conf = $$parsed{ $self->{Lexicals}{Config} }),
        'config lexical defined'
    );

    if (ref($lex_conf) eq 'HASH') {
        $self->ok(1, 'config lexical is a hash reference');
    } else {
        $lex_conf = {};
    }

    return $lex_conf;
}
    




sub wrap_columns { shift; $Text::Wrap::columns = shift; }



sub ok_object {
    my($class, $obj) = (shift, shift);

    unless (defined $obj) {
        $obj = $class;

        die("usage: obj->ok_object() or class->ok_object(object)\n")
            unless ref($obj);

    }

    return $ok_object = $obj;
}



sub tests {
    my($self, $count) = (shift, shift);

    print("1..$count\n");
    $self->{Test_Count} = $count;
}



sub ok {
    my($self, $test, $comment);

    if (@_ == 2 || @_ == 1) {
        $test    = shift;
        $comment = shift;

        unless (defined $ok_object) {
            die(
                "ok() method called with no object, ",
                "and no \$ok_object defined.\n"
            );
        }
            
        $self = $ok_object;

    } else {
        $self    = shift;
        $test    = shift;
        $comment = shift;
    }


    my $method;
    $method  = (split /::/, (caller(1))[3])[-1] if caller(1);


    my($program, $line);
    {
        my $stacklevel;
        for ($stacklevel = -1; caller($stacklevel + 1); $stacklevel++){}

        $program = (caller($stacklevel))[1];
        $line    = (caller($stacklevel))[2];
    }


    my $prefix = '';
    if (defined $comment) {
        if (defined $method) {
            $comment = "$program:$line $method - $comment";
            $prefix  = " " x length("$program:$line $method - ");
        } else {
            $comment = "$program:$line - $comment";
            $prefix  = " " x length("$program:$line - ");
        }

    } else {
        if (defined $method) {
            $comment = "$program line $line - $method() test";

        } elsif ((caller(0))[0] eq 'main') {
            $comment = "$program line $line";
        }
    }

    print(
        wrap("# ", "# $prefix", "$comment"), "\n",
        ($test ? '' : 'not '), 'ok ', $self->{Test_Number}++, "\n\n"
    );
}




sub symbols { keys %{ shift->symbol_search(@_) } }


sub symbol_search {
    my $self = shift;
    my %args = @_;

    my(@wanted_types, @unwanted_types);

    foreach my $pair (
        [ 'Type',       \@wanted_types   ],
        [ 'NotType',    \@unwanted_types ]
    ) {
        my $key = $$pair[0];

        if (defined $args{$key}) {
            if (ref($args{$key}) eq 'ARRAY') {
                @{$$pair[1]} = @{$args{$key}};
            } else {
                @{$$pair[1]} = $args{$key};
            }
        }
    }
        


    my %matching_symbols = %{$self->{Symbols}};
    if (@wanted_types) {

        my @non_matches;
        while (my($sym, $avail_types) = each(%matching_symbols)) {

            foreach my $wanted_type (@wanted_types) {
                unless (grep { $_ eq $wanted_type }
                                @$avail_types
                ) {
                    push(@non_matches, $sym);
                    last;
                }
            }
        }

        delete @matching_symbols{@non_matches};
    }


    if (@unwanted_types) {

        my @non_matches;
        while (my($sym, $avail_types) = each(%matching_symbols)) {

            foreach my $unwanted_type (@unwanted_types) {
                if (grep { $_ eq $unwanted_type }
                                @$avail_types
                ) {
                    push(@non_matches, $sym);
                    last;
                }
            }
        }

        delete @matching_symbols{@non_matches};
    }


    return \%matching_symbols;
}
