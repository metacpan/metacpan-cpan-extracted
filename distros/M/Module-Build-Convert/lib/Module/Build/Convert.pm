package Module::Build::Convert;

use 5.005;
use strict;
use warnings;

use Carp ();
use Cwd ();
use Data::Dumper ();
use ExtUtils::MakeMaker ();
use File::Basename ();
use File::HomeDir ();
use File::Slurp ();
use File::Spec ();
use IO::File ();
use IO::Prompt ();
use PPI ();
use Text::Balanced ();

our $VERSION = '0.49';

use constant LEADCHAR => '* ';

sub new {
    my ($self, %params) = @_;
    my $class = ref($self) || $self;

    my $obj = bless { Config => { Path                => $params{Path}                || '',
                                  Makefile_PL         => $params{Makefile_PL}         || 'Makefile.PL',
                                  Build_PL            => $params{Build_PL}            || 'Build.PL',
                                  MANIFEST            => $params{MANIFEST}            || 'MANIFEST',
                                  RC                  => $params{RC}                  || '.make2buildrc',
                                  Dont_Overwrite_Auto => $params{Dont_Overwrite_Auto} || 1,
                                  Create_RC           => $params{Create_RC}           || 0,
                                  Parse_PPI           => $params{Parse_PPI}           || 0,
                                  Exec_Makefile       => $params{Exec_Makefile}       || 0,
                                  Verbose             => $params{Verbose}             || 0,
                                  Debug               => $params{Debug}               || 0,
                                  Process_Code        => $params{Process_Code}        || 0,
                                  Use_Native_Order    => $params{Use_Native_Order}    || 0,
                                  Len_Indent          => $params{Len_Indent}          || 3,
                                  DD_Indent           => $params{DD_Indent}           || 2,
                                  DD_Sortkeys         => $params{DD_Sortkeys}         || 1 }}, $class;

    $obj->{Config}{RC} = File::Spec->catfile(File::HomeDir::home(), $obj->{Config}{RC});

    # Save length of filename for creating underlined title in output
    $obj->{Config}{Build_PL_Length} = length($obj->{Config}{Build_PL});

    return $obj;
}

sub convert {
    my $self = shift;

    unless ($self->{Config}{reinit} || @{$self->{dirs}||[]}) {
        if ($self->{Config}{Path}) {
            if (-f $self->{Config}{Path}) {
                my ($basename, $dirname)     = File::Basename::fileparse($self->{Config}{Path});
                $self->{Config}{Makefile_PL} = $basename;
                $self->{Config}{Path}        = $dirname;
            }

            opendir(my $dh, $self->{Config}{Path}) or die "Can't open $self->{Config}{Path}\n";
            @{$self->{dirs}} = grep { /[\w\-]+[\d\.]+/
              and -d File::Spec->catfile($self->{Config}{Path}, $_) } sort readdir $dh;

            unless (@{$self->{dirs}}) {
                unshift @{$self->{dirs}}, $self->{Config}{Path};
                $self->{have_single_dir} = 1;
            }
        } else {
            unshift @{$self->{dirs}}, '.';
            $self->{have_single_dir} = 1;
        }
    }

    my $Makefile_PL = File::Basename::basename($self->{Config}{Makefile_PL});
    my $Build_PL    = File::Basename::basename($self->{Config}{Build_PL});
    my $MANIFEST    = File::Basename::basename($self->{Config}{MANIFEST});

    unshift @{$self->{dirs}}, $self->{current_dir} if $self->{Config}{reinit};

    $self->{show_summary} = 1 if @{$self->{dirs}} > 1;

    while (my $dir = shift @{$self->{dirs}}) {
        $self->{current_dir} = $dir;

        %{$self->{make_args}} = ();

        unless ($self->{have_single_dir}) {
            local $" = "\n";
            $self->_do_verbose(<<TITLE) if !$self->{Config}{reinit};
Remaining dists:
----------------
$dir
@{$self->{dirs}}

TITLE
        }

        $dir = File::Spec->catfile($self->{Config}{Path}, $dir) if !$self->{have_single_dir};
        $self->{Config}{Makefile_PL} = File::Spec->catfile($dir, $Makefile_PL);
        $self->{Config}{Build_PL}    = File::Spec->catfile($dir, $Build_PL);
        $self->{Config}{MANIFEST}    = File::Spec->catfile($dir, $MANIFEST);

        unless ($self->{Config}{reinit}) {
            no warnings 'uninitialized';

            $self->_do_verbose(LEADCHAR."Converting $self->{Config}{Makefile_PL} -> $self->{Config}{Build_PL}\n");

            my $skip_msg  = LEADCHAR."Skipping $self->{Config}{Path}\n";
               $skip_msg .= "\n" if @{$self->{dirs}};

            $self->_create_rcfile if $self->{Config}{Create_RC};

            if (!$self->_exists_overwrite || !$self->_makefile_ok) {
                $self->_do_verbose($skip_msg);
                next;
            }

            $self->_get_data;
        }

        $self->_extract_args;
        $self->_register_summary;
        $self->_convert;
        $self->_dump;
        $self->_write;
        $self->_add_to_manifest if -e $self->{Config}{MANIFEST};
    }

    $self->_show_summary if $self->{show_summary};
}

sub _exists_overwrite {
    my $self = shift;

    if (-e $self->{Config}{Build_PL}) {
        print "$self->{current_dir}:\n"
          if $self->{show_summary} && !$self->{Config}{Verbose};

        print "\n" if $self->{Config}{Verbose};
        print 'A Build.PL exists already';

        if ($self->{Config}{Dont_Overwrite_Auto}) {
            print ".\n";
            my $input_ok = IO::Prompt::prompt -yn, 'Shall I overwrite it? ';

            if (!$input_ok) {
                print "Skipped...\n";
                print "\n" if $self->{Config}{Verbose};
                push @{$self->{summary}{skipped}}, $self->{current_dir};
                return 0;
            } else {
                print "\n" if $self->{Config}{Verbose};
            }
        } else {
            print ", continuing...\n";
        }
    }

    return 1;
}

sub _create_rcfile {
    my $self = shift;

    my $rcfile = $self->{Config}{RC};

    if (-e $rcfile && !-z $rcfile && File::Slurp::read_file($rcfile) =~ /\w+/) {
        die "$rcfile exists\n";
    } else {
        my $data = $self->_parse_data('create_rc');
        my $fh = IO::File->new($rcfile, '>') or die "Can't open $rcfile: $!\n";
        print {$fh} $data;
        $fh->close;
        print LEADCHAR."Created $rcfile\n";
        exit;
    }
}

sub _makefile_ok {
    my $self = shift;

    my $makefile;

    if (-e $self->{Config}{Makefile_PL}) {
        $makefile = File::Slurp::read_file($self->{Config}{Makefile_PL});
    } else {
        die 'No ', File::Basename::basename($self->{Config}{Makefile_PL}), ' found at ',
          $self->{Config}{Path}
            ? File::Basename::dirname($self->{Config}{Makefile_PL}) 
            : Cwd::cwd(), "\n";
    }

    my $max_failures = 2;
    my ($failed, @failures);

    if ($makefile =~ /use\s+inc::Module::Install/) {
        push @failures, "Unsuitable Makefile: Module::Install being used";
        $failed++;
    }

    unless ($makefile =~ /WriteMakefile\s*\(/s) {
        push @failures, "Unsuitable Makefile: doesn't consist of WriteMakefile()";
        $failed++;
    }

    if (!$failed && $makefile =~ /WriteMakefile\(\s*%\w+.*\s*\)/s && !$self->{Config}{Exec_Makefile}) {
        $self->_do_verbose(LEADCHAR."Indirect arguments to WriteMakefile() via hash detected, setting executing mode\n");
        $self->{Config}{Exec_Makefile} = 1;
    }

    if ($failed) {
        my ($i, $output);

        $output .= "\n" if $self->{Config}{Verbose} && @{$self->{dirs}};
        $output .= join '', map { $i++; "[$i] $_\n" } @failures;
        $output .= "$self->{current_dir}: Failed $failed/$max_failures.\n";
        $output .= "\n" if $self->{Config}{Verbose} && @{$self->{dirs}};

        print $output;

        push @{$self->{summary}{failed}}, $self->{current_dir};

        return 0;
    }

    return 1;
}

sub _get_data {
    my $self = shift;
    my @data = $self->_parse_data;

    $self->{Data}{table}           = { split /\s+/, shift @data };
    $self->{Data}{default_args}    = { split /\s+/, shift @data };
    $self->{Data}{sort_order}      = [ split /\s+/, shift @data ];
   ($self->{Data}{begin}, 
    $self->{Data}{end})            =                      @data;

    # allow for embedded values such as clean => { FILES => '' }
    foreach my $arg (keys %{$self->{Data}{table}}) {
        if (index($arg, '.') > 0) {
            my @path = split /\./, $arg;
            my $value = $self->{Data}{table}->{$arg};
            my $current = $self->{Data}{table};
            while (@path) {
                my $key = shift @path;
                $current->{$key} ||= @path ? {} : $value;
                $current = $current->{$key};
            }
        }
    }
}

sub _parse_data {
    my $self = shift;
    my $create_rc = 1 if (shift || 'undef') eq 'create_rc';

    my ($data, @data_parsed);
    my $rcfile = $self->{Config}{RC};

    if (-e $rcfile && !-z $rcfile && File::Slurp::read_file($rcfile) =~ /\w+/) {
        $data = File::Slurp::read_file($rcfile);
    } else {
        if (!defined $self->{DATA}) {
            local $/ = '__END__';
            $data = <DATA>;
            chomp $data;
	    $self->{DATA} = $data;
	} else {
	    $data = $self->{DATA};
	}
    }

    unless ($create_rc) {
        @data_parsed = do {               #  # description
            split /#\s+.*\s+?-\n/, $data; #  -
        };
    }

    unless ($create_rc) {
        # superfluosity
        shift @data_parsed;
        chomp $data_parsed[-1];

        foreach my $line (split /\n/, $data_parsed[0]) {
            next unless $line;

            if ($line =~ /^#/) {
                my ($arg) = split /\s+/, $line;
                $self->{disabled}{substr($arg, 1)} = 1;
            }
        }

        @data_parsed = map { 1 while s/^#.*?\n(.*)$/$1/gs; $_ } @data_parsed;
    }

    return $create_rc ? $data : @data_parsed;
}

sub _extract_args {
    my $self = shift;

    if ($self->{Config}{Exec_Makefile}) {
        $self->_do_verbose(LEADCHAR."Executing $self->{Config}{Makefile_PL}\n");
        $self->_run_makefile;
    } else {
        if ($self->{Config}{Parse_PPI}) {
            $self->_parse_makefile_ppi;
        } else {
            $self->_parse_makefile;
        }
    }
}

sub _register_summary {
    my $self = shift;

    push @{$self->{summary}->{succeeded}}, $self->{current_dir};

    push @{$self->{summary}{$self->{Config}{Exec_Makefile} ? 'method_execute' : 'method_parse'}},
           $self->{current_dir};

    $self->{Config}{Exec_Makefile} =
           $self->{Config}{reinit} = 0;
}

sub _run_makefile {
    my $self = shift;
    no warnings 'redefine';

    *ExtUtils::MakeMaker::WriteMakefile = sub {
      %{$self->{make_args}{args}} = @{$self->{make_args_arr}} = @_;
    };

    # beware, do '' overwrites existing globals
    $self->_save_globals;
    do $self->{Config}{Makefile_PL};
    $self->_restore_globals;
}

sub _save_globals {
    my $self = shift;
    my @vars;

    my $makefile = File::Slurp::read_file($self->{Config}{Makefile_PL});
    $makefile =~ s/.*WriteMakefile\(\s*?(.*?)\);.*/$1/s;

    while ($makefile =~ s/\$(\w+)//) {
        push @vars, $1 if defined ${$1};
    }

    no strict 'refs';
    foreach my $var (@vars) {
        ${__PACKAGE__.'::globals'}{$var} = ${$var};
    }
}

sub _restore_globals {
    my $self = shift;
    no strict 'refs';

    while (my ($var, $value) = each %{__PACKAGE__.'::globals'}) {
        ${__PACKAGE__.'::'.$var} = $value;
    }
    undef %{__PACKAGE__.'::globals'};
}

sub _parse_makefile_ppi {
    my $self = shift;

    $self->_parse_init;

    ($self->{parse}{makefile}, $self->{make_code}{begin}, $self->{make_code}{end}) = $self->_read_makefile;

    $self->_debug(LEADCHAR."Entering parse\n\n", 'no_wait');

    my $doc = PPI::Document->new(\$self->{parse}{makefile});

    my @elements = $doc->children;
    my @tokens   = $elements[0]->tokens;

    $self->_scrub_ternary(\@tokens);

    my ($keyword, %have, @items, %seen, $structure_ended, $type);

    for (my $i = 0; $i < @tokens; $i++) {
        my %token = (curr => sub {
                                      my $c = $i; 
                                      while (!$tokens[$c]->significant) { $c++ }
                                      $i = $c;
                                      return $tokens[$c];
                                 },

                     next => sub {
                                      my $iter      = $_[0] ? $_[0] : 1;
                                      my ($c, $pos) = ($i + 1, 0);

                                      while ($c < @tokens) {
                                          $pos++ if $tokens[$c]->significant;
                                          last if $pos == $iter;
                                          $c++;
                                      }

                                      return $tokens[$c];
                                 },

                     last => sub {
                                      my $iter      = $_[0] ? $_[0] : 1;
                                      my ($c, $pos) = ($i, 0);

                                      $c-- if $c >= 1;

                                      while ($c > 0) { 
                                          $pos++ if $tokens[$c]->significant;
                                          last if $pos == $iter;
                                          $c--;
                                      }

                                      return $tokens[$c];
                                 });

        my %finalize = (string => sub { $self->{parse}{makeargs}{$keyword} = join '', @items },
                        array  => sub { $self->{parse}{makeargs}{$keyword} = [ @items      ] },
                        hash   => sub { $self->{parse}{makeargs}{$keyword} = { @items      } });

        my $token = $have{code} ? $tokens[$i] : $token{curr}->();

        if ($self->_is_quotelike($token) && !$have{code} && !$have{nested_structure} && $token{last}->(1) ne '=>') {
            $keyword = $token;
            $type    = 'string';
            next;
        } elsif ($token eq '=>' && !$have{nested_structure}) {
            next;
        }

        next if $structure_ended && $token eq ',';
        $structure_ended = 0;

        if ($token->isa('PPI::Token::Structure') && !$have{code}) {
            if ($token =~ /[\Q[{\E]/) {
                $have{nested_structure}++;

                my %assoc = ('[' => 'array',
                             '{' => 'hash');

                $type = $assoc{$token};
            } elsif ($token =~ /[\Q]}\E]/) {
                $have{nested_structure}--;
                $structure_ended = 1 unless $have{nested_structure};
            }
        }

        $structure_ended = 1 if  $token{next}->() eq ',' && !$have{code} && !$have{nested_structure};
        $have{code}      = 1 if  $token->isa('PPI::Token::Word') && $token{next}->(1) ne '=>';

        if ($have{code}) {
            my $followed_by_arrow = sub { $token eq ',' && $token{next}->(2) eq '=>' };

            my %finalize = (seen   => sub { $structure_ended = 1; $seen{code} = 1; $have{code} = 0 },
                            unseen => sub { $structure_ended = 1; $seen{code} = 0; $have{code} = 0 });

            if ($followed_by_arrow->()) {
                ($token{next}->(1) =~ /^[\Q}]\E]$/ || !$have{nested_structure})
                  ? $finalize{seen}->()
                  : $have{nested_structure}
                    ? $finalize{unseen}->()
                    : ();
            } elsif (($token eq ',' && $token{next}->(1) eq ']')
                   || $token{next}->(1) eq ']') {
                      $finalize{unseen}->();
            }
        }

        unless ($token =~ /^[\Q[]{}\E]$/ && !$have{code}) {
            next if $token eq '=>';
            next if $token eq ',' && !$have{code} && !$seen{code};

            if (defined $keyword) {
                $keyword =~ s/['"]//g;
                $token   =~ s/['"]//g unless $token =~ /^['"]\s+['"]$/ || $have{code};

                if (!$have{code} && !$structure_ended) {
                    push @items, $token;
                } else {
                    if ((@items % 2 == 1 && $type ne 'array') || !@items) {
                        push @items, $token;
                    } else {
                        $items[-1] .= $token unless $structure_ended
                                                 && $type eq 'string';
                    }
                }
            }
        }

        if ($structure_ended && @items) {
            # Obscure construct. Needed to 'serialize' the PPI tokens.
            @items = map { /(.*)/; $1 } @items;

            # Sanitize code elements within a hash.
            $items[-1] =~ s/[,\s]+$// if $type eq 'hash' && defined $items[-1];

            $finalize{$type}->();

            undef $keyword;

            $have{code} = 0;
            @items      = ();
            %seen       = ();

            $type = 'string';
        }
    }

    $self->_debug(LEADCHAR."Leaving parse\n\n", 'no_wait');

    %{$self->{make_args}{args}} = %{$self->{parse}{makeargs}};
}

sub _is_quotelike {
    my ($self, $token) = @_;

    return ($token->isa('PPI::Token::Double')
         or $token->isa('PPI::Token::Quote::Interpolate')
         or $token->isa('PPI::Token::Quote::Literal')
         or $token->isa('PPI::Token::Quote::Single')
         or $token->isa('PPI::Token::Word')) ? 1 : 0;
}

sub _scrub_ternary {
    my ($self, $tokens) = @_;

    my (%last, %have, %occurences);

    for (my $i = 0; $i < @$tokens; $i++) {
        my $token = $tokens->[$i];

        $last{comma} = $i if $token eq ',' && !$have{'?'};

        unless ($have{ternary}) {
            $occurences{subsequent}{'('}++ if $token eq '(';
            $occurences{subsequent}{')'}++ if $token eq ')';
        }

        $have{'?'} = 1 if $token eq '?';
        $have{':'} = 1 if $token eq ':';

        $have{ternary} = 1 if $have{'?'} && $have{':'};

        if ($have{ternary}) {
            $occurences{'('} ||= 0;
            $occurences{')'} ||= 0;

            $occurences{'('} += $occurences{subsequent}{'('};
            $occurences{')'} += $occurences{subsequent}{')'};

            $occurences{subsequent}{'('} = 0;
            $occurences{subsequent}{')'} = 0;

            $occurences{'('}++ if $token eq '(';
            $occurences{')'}++ if $token eq ')';

            $have{parentheses} = 1 if $occurences{'('} || $occurences{')'};
            $have{comma}       = 1 if $token eq ',';

            if ($occurences{'('} == $occurences{')'} && $have{parentheses} && $have{comma}) {
                $i++ while $tokens->[$i] ne ',';
                splice(@$tokens, $last{comma}, $i-$last{comma});

                @have{qw(? : comma parentheses ternary)} = (0,0,0,0,0);
                @occurences{qw{( )}}                     = (0,0);

                $i = 0; redo;
            }
        }
    }
}

sub _parse_makefile {
    my $self = shift;

    $self->_parse_init;

    ($self->{parse}{makefile}, $self->{make_code}{begin}, $self->{make_code}{end}) = $self->_read_makefile;
    my ($found_string, $found_array, $found_hash) = $self->_parse_regexps;

    $self->_debug(LEADCHAR."Entering parse\n\n", 'no_wait');

    while ($self->{parse}{makefile}) {
        $self->{parse}{makefile} .= "\n" 
          unless $self->{parse}{makefile} =~ /\n$/s;

        # process string
        if ($self->{parse}{makefile} =~ s/$found_string//) {
            $self->_parse_process_string($1,$2,$3);
            $self->_parse_register_comment;
            $self->_debug($self->_debug_string_text);
        # process array
        } elsif ($self->{parse}{makefile} =~ s/$found_array//s) {
            $self->_parse_process_array($1,$2,$3);
            $self->_parse_register_comment;
            $self->_debug($self->_debug_array_text);
        # process hash
        } elsif ($self->{parse}{makefile} =~ s/$found_hash//s) {
            $self->_parse_process_hash($1,$2,$3);
            $self->_parse_register_comment;
            $self->_debug($self->_debug_hash_text);
        # process "code"
        } else {
            chomp $self->{parse}{makefile};

            $self->_parse_process_code;
            $self->_parse_catch_trapped_loop;

            if ($self->{Config}{Process_Code}) {
                $self->_parse_substitute_makeargs;
                $self->_parse_append_makecode;
                $self->_debug($self->_debug_code_text);
            }
        }

        $self->{parse}{makefile} = ''
          unless $self->{parse}{makefile} =~ /\w/;
    }

    $self->_debug(LEADCHAR."Leaving parse\n\n", 'no_wait');

    %{$self->{make_args}{args}} = %{$self->{parse}{makeargs}};
}

sub _parse_init {
    my $self = shift;

    %{$self->{make_code}} = ();
    %{$self->{parse}}     = ();
}

sub _parse_regexps {
    my $self = shift;

    my $found_string = qr/^
                            \s* 
                            ['"]? (\w+) ['"]?
                            \s* => \s* (?![ \{ \[ ])
                            ['"]? ([\$ \@ \% \< \> \( \) \\ \/ \- \: \. \w]+.*?) ['"]?
                            ,? ([^\n]+ \# \s+ \w+ .*?)? \n
                       /sx;
    my $found_array  = qr/^
                            \s*
                            ['"]? (\w+) ['"]?
                            \s* => \s*
                            \[ \s* (.*?) \s* \]
                            ,? ([^\n]+ \# \s+ \w+ .*?)? \n
                       /sx;
    my $found_hash   = qr/^
                            \s*
                            ['"]? (\w+) ['"]?
                            \s* => \s*
                            \{ \s* (.*?) \s*? \}
                            ,? ([^\n]+ \# \s+ \w+ .*?)? \n
                       /sx;

    return ($found_string, $found_array, $found_hash);
}

sub _parse_process_string {
    my ($self, $arg, $value, $comment) = @_;

    $value   ||= '';
    $comment ||= '';

    $value =~ s/^['"]//;
    $value =~ s/['"]$//;

    $self->{parse}{makeargs}{$arg} = $value;
    push @{$self->{parse}{histargs}}, $arg;

    $self->{parse}{arg}     = $arg;
    $self->{parse}{value}   = $value;
    $self->{parse}{comment} = $comment;
}

sub _parse_process_array {
    my ($self, $arg, $values, $comment) = @_;

    $values  ||= '';
    $comment ||= '';

    $self->{parse}{makeargs}{$arg} = [ map { tr/['",]//d; $_ } split /,\s*/, $values ];
    push @{$self->{parse}{histargs}}, $arg;

    $self->{parse}{arg}     = $arg;
    $self->{parse}{values}  = $self->{parse}{makeargs}{$arg},
    $self->{parse}{comment} = $comment;
}


sub _parse_process_hash {
    my ($self, $arg, $values, $comment) = @_;

    $values  ||= '';
    $comment ||= '';

    my @values_debug = split /,\s*/, $values;
    my @values;

    foreach my $value (@values_debug) {
        push @values, map { tr/['",]//d; $_ } split /\s*=>\s*/, $value;
    }

    @values_debug = map { "$_\n        " } @values_debug;

    $self->{parse}{makeargs}{$arg} = { @values };
    push @{$self->{parse}{histargs}}, $arg;

    $self->{parse}{arg}     = $arg;
    $self->{parse}{values}  = \@values_debug,
    $self->{parse}{comment} = $comment;
}

sub _parse_process_code {
    my $self = shift;

    my ($debug_desc, $retval);

    my @code     = Text::Balanced::extract_codeblock($self->{parse}{makefile}, '()');
    my @variable = Text::Balanced::extract_variable($self->{parse}{makefile});

    # [0] extracted
    # [1] remainder

    if ($code[0]) {
        $code[0] =~ s/^\s*\(\s*//s;
        $code[0] =~ s/\s*\)\s*$//s;

        $code[0] =~ s/\s*=>\s*/\ =>\ /gs;
        $code[1] =~ s/^\s*,//;

        $self->{parse}{makefile} = $code[1];
        $retval                  = $code[0];

        $debug_desc = 'code';
    } elsif ($variable[0]) {
        $self->{parse}{makefile} = $variable[1];
        $retval                  = $variable[0];

        $debug_desc = 'variable';
    } elsif ($self->{parse}{makefile} =~ /\#/) {
        my $comment;

        $self->{parse}{makefile} .= "\n"
          unless $self->{parse}{makefile} =~ /\n$/s;

        while ($self->{parse}{makefile} =~ /\G(\s*?\#.*?\n)/cgs) {
            $comment .= $1;
        }

        $comment ||= '';

        my $quoted_comment = quotemeta $comment;
        $self->{parse}{makefile} =~ s/$quoted_comment//s; 

        my @comment;

        @comment = split /\n/,   $comment;
        @comment = grep { /\#/ } @comment;

        foreach $comment (@comment) {
            $comment =~ s/^\s*?(\#.*)$/$1/gm;
            chomp $comment;
        }

        $retval     = \@comment;
        $debug_desc = 'comment';
    } else {
        $retval     = '';
        $debug_desc = 'unclassified';
    }

    $self->{parse}{debug_desc} = $debug_desc;
    $self->{parse}{makecode}   = $retval;
}

sub _parse_catch_trapped_loop {
    my $self = shift;

    no warnings 'uninitialized';

    $self->{parse}{trapped_loop}{$self->{parse}{makecode}}++
      if $self->{parse}{makecode} eq $self->{makecode_prev};

    if ($self->{parse}{trapped_loop}{$self->{parse}{makecode}} > 1) {
        $self->{Config}{Exec_Makefile} = 1;
        $self->{Config}{reinit}        = 1;
        $self->convert;
        exit;
    }

    $self->{makecode_prev} = $self->{parse}{makecode};
}

sub _parse_substitute_makeargs {
    my $self = shift;

    $self->{parse}{makecode} ||= '';

    foreach my $make (keys %{$self->{Data}{table}}) {
        if ($self->{parse}{makecode} =~ /\b$make\b/s) {
            $self->{parse}{makecode} =~ s/$make/$self->{Data}{table}{$make}/;
       }
    }
}

sub _parse_append_makecode {
    my $self = shift;

    unless (@{$self->{parse}{histargs}||[]}) {
        push @{$self->{make_code}{args}{begin}}, $self->{parse}{makecode};
    } else {
        pop @{$self->{parse}{histargs}}
          until $self->{Data}{table}{$self->{parse}{histargs}->[-1]};

        push @{$self->{make_code}{args}{$self->{Data}{table}{$self->{parse}{histargs}->[-1]}}},
               $self->{parse}{makecode};
    }
}

sub _parse_register_comment {
    my $self = shift;

    my $arg     = $self->{parse}{arg};
    my $comment = $self->{parse}{comment};

    if (defined($comment) && defined($self->{Data}{table}{$arg})) {
        $self->{make_comments}{$self->{Data}{table}{$arg}} = $comment;
    }
}

sub _debug_string_text {
    my $self = shift;

    my $output = <<EOT;
Found string ''
+++++++++++++++
\$arg: $self->{parse}{arg}
\$value: $self->{parse}{value}
\$comment: $self->{parse}{comment}
\$remaining args:
$self->{parse}{makefile}

EOT
    return $output;
}

sub _debug_array_text {
    my $self = shift;

    my @values = @{$self->{parse}{values}};

    my $output = <<EOT;
Found array []
++++++++++++++
\$arg: $self->{parse}{arg}
\$values: @values
\$comment: $self->{parse}{comment}
\$remaining args:
$self->{parse}{makefile}

EOT
    return $output;
}

sub _debug_hash_text {
    my $self = shift;

    my $output = <<EOT;
Found hash {}
+++++++++++++
\$key: $self->{parse}{arg}
\$values: @{$self->{parse}{values}}
\$comment: $self->{parse}{comment}
\$remaining args:
$self->{parse}{makefile}
EOT
    return $output;
}

sub _debug_code_text {
    my $self = shift;

    my @args;

    if (ref $self->{parse}{makecode} eq 'ARRAY') {
        push @args, @{$self->{parse}{makecode}};
    } else {
        push @args, $self->{parse}{makecode};
    }

    @args = map { "\n$_" } @args if @args > 1;

    my $output = <<EOT;
Found code &
++++++++++++
$self->{parse}{debug_desc}: @args
remaining args:
$self->{parse}{makefile}

EOT
    return $output;
}

sub _read_makefile {
    my $self = shift;

    my $makefile = File::Slurp::read_file($self->{Config}{Makefile_PL});
    $makefile =~ s/^(.*?)\&?WriteMakefile\s*?\(\s*(.*?)\s*\)\s*?;(.*)$/$2/s;

    my $makecode_begin = $1;
    my $makecode_end   = $3;
    $makecode_begin    =~ s/\s*([\#\w]+.*)\s*/$1/s;
    $makecode_end      =~ s/\s*([\#\w]+.*)\s*/$1/s;

    return ($makefile, $makecode_begin, $makecode_end);
}

sub _convert {
    my $self = shift;

    $self->_insert_args;

    foreach my $arg (keys %{$self->{make_args}{args}}) {
        if ($self->{disabled}{$arg}) {
            $self->_do_verbose(LEADCHAR."$arg disabled, skipping\n");
            next;
        }
        unless ($self->{Data}{table}->{$arg}) {
            $self->_do_verbose(LEADCHAR."$arg unknown, skipping\n");
            next;
        }
        if (ref $self->{make_args}{args}{$arg} eq 'HASH') {
            if (ref $self->{Data}{table}->{$arg} eq 'HASH') {
                # embedded structure
                my @iterators = ();
                my $current = $self->{Data}{table}->{$arg};
                my $value = $self->{make_args}{args}{$arg};
                push @iterators, _iterator($current, $value, keys %$current);
                while (@iterators) {
                    my $iterator = shift @iterators;
                    while (($current, $value) = $iterator->()) {
                        if (ref $current eq 'HASH') {
                            push @iterators, _iterator($current, $value, keys %$current);
                        } else {
                            if (substr($current, 0, 1) eq '@') {
                                my $attr = substr($current, 1);
                                if (ref $value eq 'ARRAY') {
                                    push @{$self->{build_args}}, { $attr => $value };
                                } else {
                                    push @{$self->{build_args}}, { $attr => [ split ' ', $value ] };
                                }
                            } else {
                                push @{$self->{build_args}}, { $current => $value };
                            }
                        }
                    }
                }
            } else {
                # flat structure
                my %tmphash;
                %{$tmphash{$self->{Data}{table}->{$arg}}} =
                  map { $_ => $self->{make_args}{args}{$arg}{$_} } keys %{$self->{make_args}{args}{$arg}};
                push @{$self->{build_args}}, \%tmphash;
            }
        } elsif (ref $self->{make_args}{args}{$arg} eq 'ARRAY') { 
            push @{$self->{build_args}}, { $self->{Data}{table}->{$arg} => $self->{make_args}{args}{$arg} };
        } elsif (ref $self->{make_args}{args}{$arg} eq '') {
            push @{$self->{build_args}}, { $self->{Data}{table}->{$arg} => $self->{make_args}{args}{$arg} };
        } else { # unknown type
            warn "$arg - unknown type of argument\n";
        }
    }

    $self->_sort_args if @{$self->{Data}{sort_order}};
}

sub _insert_args {
    my ($self, $make) = @_;

    my @insert_args;
    my %build = map { $self->{Data}{table}{$_} => $_ } keys %{$self->{Data}{table}};

    while (my ($arg, $value) = each %{$self->{Data}{default_args}}) {
        no warnings 'uninitialized';

        if (exists $self->{make_args}{args}{$build{$arg}}) {
            $self->_do_verbose(LEADCHAR."Overriding default \'$arg => $value\'\n");
            next;
        }

        $value = {} if $value eq 'HASH';
        $value = [] if $value eq 'ARRAY';
        $value = '' if $value eq 'SCALAR' && $value !~ /\d+/;

        push @insert_args, { $arg => $value };
    }

    @{$self->{build_args}} = @insert_args;
}

sub _iterator {
    my ($build, $make) = (shift, shift);
    my @queue = @_;

    return sub {
        my $key = shift @queue || return;
        return $build->{$key}, $make->{$key};
    }
}

sub _sort_args {
    my $self = shift;

    my %native_sortorder;

    if ($self->{Config}{Use_Native_Order}) {
        no warnings 'uninitialized';

        # Mapping an incremental value to the arguments (keys) in the
        # order they appear.
        for (my ($i,$s) = 0; $s < @{$self->{make_args_arr}}; $s++) {
            # Skipping values
            next unless $s % 2 == 0;
            # Populating table with according M::B arguments and counter
            $native_sortorder{$self->{Data}{table}{$self->{make_args_arr}[$s]}} = $i
              if exists $self->{Data}{table}{$self->{make_args_arr}[$s]};
            $i++;
        }
    }

    my %sortorder;
    {
        my %have_args = map { keys %$_ => 1 } @{$self->{build_args}};
        # Filter sort items, that we didn't receive as args,
        # and map the rest to according array indexes.
        my $i = 0;
        if ($self->{Config}{Use_Native_Order}) {
            my %slot;

            foreach my $arg (grep $have_args{$_}, @{$self->{Data}{sort_order}}) {
                # Building sorting table for existing MakeMaker arguments
                if ($native_sortorder{$arg}) {
                    $sortorder{$arg} = $native_sortorder{$arg};
                    $slot{$native_sortorder{$arg}} = 1;
                # Inject default arguments at free indexes
                } else {
                    $i++ while $slot{$i};
                    $sortorder{$arg} = $i++;
                }
            }

            # Sorting sort table ascending
            my @args = sort { $sortorder{$a} <=> $sortorder{$b} } keys %sortorder;
            $i = 0; %sortorder = map { $_ => $i++ } @args;

        } else {
            %sortorder = map {
              $_ => $i++
            } grep $have_args{$_}, @{$self->{Data}{sort_order}};
        }
    }

    my ($is_sorted, @unsorted);
    do {

        $is_sorted = 1;

          SORT: for (my $i = 0; $i < @{$self->{build_args}}; $i++) {
              my ($arg) = keys %{$self->{build_args}[$i]};

              unless (exists $sortorder{$arg}) {
                  push @unsorted, splice(@{$self->{build_args}}, $i, 1);
                  next;
              }

              if ($i != $sortorder{$arg}) {
                  $is_sorted = 0;
                  # Move element $i to pos $sortorder{$arg}
                  # and the element at $sortorder{$arg} to
                  # the end.
                  push @{$self->{build_args}},
                    splice(@{$self->{build_args}}, $sortorder{$arg}, 1,
                      splice(@{$self->{build_args}}, $i, 1));

                  last SORT;
              }
          }
    } until ($is_sorted);

    push @{$self->{build_args}}, @unsorted;
}

sub _dump {
    my $self = shift;

    $Data::Dumper::Indent    = $self->{Config}{DD_Indent} || 2;
    $Data::Dumper::Quotekeys = 0;
    $Data::Dumper::Sortkeys  = $self->{Config}{DD_Sortkeys};
    $Data::Dumper::Terse     = 1;

    my $d = Data::Dumper->new(\@{$self->{build_args}});
    $self->{buildargs_dumped} = [ $d->Dump ];
}

sub _write { 
    my $self = shift;

    $self->{INDENT} = ' ' x $self->{Config}{Len_Indent};

    no warnings 'once';
    my $fh = IO::File->new($self->{Config}{Build_PL}, '>') 
      or die "Can't open $self->{Config}{Build_PL}: $!\n";

    my $selold = select($fh);

    $self->_compose_header;
    $self->_write_begin;
    $self->_write_args;
    $self->_write_end;
    $fh->close;

    select($selold);

    $self->_do_verbose("\n", LEADCHAR."Conversion done\n");
    $self->_do_verbose("\n") if !$self->{have_single_dir};
}

sub _compose_header {
    my $self = shift;

    my ($comments_header, $code_header);

    my $note = '# Note: this file has been initially generated by ' . __PACKAGE__ . " $VERSION";
    my $pragmas = "use strict;\nuse warnings;\n";

    # Warnings are thrown for chomp() & regular expressions when enabled
    no warnings 'uninitialized';

    if (defined $self->{make_code}{begin} || defined $self->{make_code}{end}) {
        # Removing ExtUtils::MakeMaker dependency
        $self->_do_verbose(LEADCHAR."Removing ExtUtils::MakeMaker as dependency\n");
        $self->{make_code}{begin} =~ s/[ \t]*(?:use|require)\s+ExtUtils::MakeMaker\s*;//;

        # Mapping (prompt|Verbose) calls to Module::Build ones
        if ($self->{make_code}{begin} =~ /(?:prompt|Verbose)\s*\(/s) {
            my $regexp = qr/^(.*?=\s*)(prompt|Verbose)\s*?\(['"](.*)['"]\);$/;

            foreach my $var (qw(begin end)) {
                while ($self->{make_code}{$var} =~ /$regexp/m) {
                    my $replace = $1 . 'Module::Build->' . $2 . '("' . $3 . '");';
                    $self->{make_code}{$var} =~ s/$regexp/$replace/m;
                }
            }
        }

        # Removing Module::Build::Compat Note
        if ($self->{make_code}{begin} =~ /Module::Build::Compat/) {
            $self->_do_verbose(LEADCHAR."Removing Module::Build::Compat Note\n");
            $self->{make_code}{begin} =~ s/^\#.*Module::Build::Compat.*?\n//s;
        }

        # Removing customized MakeMaker subs
        my $has_MM_sub    = qr/sub MY::/;
        my $MM_sub_prefix = 'MY::';

        foreach my $var (qw(begin end)) {
            if ($self->{make_code}{$var} =~ $has_MM_sub) {
                foreach my $sub (_extract_sub($self->{make_code}{$var}, $MM_sub_prefix)) {
                    my $quoted_sub = quotemeta $sub;
                    my ($subname)  = $sub =~ /sub.*?\s+(.*?)\s*\{/;

                    $self->{make_code}{$var} =~ s/$quoted_sub\n//;
                    $self->_do_verbose(LEADCHAR."Removing sub: '$subname'\n");
                }
            }
        }

        # Removing strict & warnings pragmas quietly here to ensure that they'll
        # be inserted after an eventually appearing version requirement.
        $self->{make_code}{begin} =~ s/[ \t]*use\s+(?:strict|warnings)\s*;//g;

        # Saving the shebang (interpreter) line
        while ($self->{make_code}{begin} =~ s/^(\#\!?.*?\n)//) {
            $comments_header .= $1;
        }
        chomp $comments_header;

        # Grabbing use & require statements
        while ($self->{make_code}{begin} =~ /^(?:use|require)\s+(?:[a-z]|[\d\.\_])+?\s*;/m) {
            $self->{make_code}{begin} =~ s/^\n*(.*?;)//s;
            $code_header .= "$1\n";
        }

        # Adding strict & warnings pragmas
        $self->_do_verbose(LEADCHAR."Adding use strict & use warnings pragmas\n");

        if ($code_header =~ /(?:use|require)\s+\d\.[\d_]*\s*;/) { 
            $code_header =~ s/([ \t]*(?:use|require)\s+\d\.[\d_]*\s*;\n)(.*)/$1$pragmas$2/;
        } else {
            $code_header = $pragmas . $code_header;
        }
        chomp $code_header;

        # Removing leading & trailing newlines
        1 while $self->{make_code}{begin} =~ s/^\n//;
        chomp $self->{make_code}{begin} while $self->{make_code}{begin} =~ /\n$/s;
    }

    # Constructing the Build.PL header
    $self->{Data}{begin} = $comments_header || $code_header
      ? ($comments_header  =~ /\w/ ? "$comments_header\n" : '') . "$note\n" .
        ($code_header =~ /\w/ ? "\n$code_header\n\n" : "\n") .
        $self->{Data}{begin}
      : "$note\n\n" . $self->{Data}{begin};
}

# Albeit Text::Balanced exists, extract_tagged() and friends
# were (or I?) unable to extract subs.
sub _extract_sub {
    my ($text, $pattern) = @_;

    my ($quoted_pattern, %seen, @sub, @subs);

    $quoted_pattern = quotemeta $pattern;

    foreach my $line (split /\n/, $text) {
        if ($line =~ /^sub $quoted_pattern\w+/s ||
            $line =~ /^\{/)                        { $seen{begin} = 1 }
        if ($seen{begin} && $line =~ /^\s*}/)      { $seen{end}   = 1 }

        if ($seen{begin} || $seen{end}) {
            push @sub, $line;
        } else {
            next;
        }

        if ($seen{end}) {
            push @subs, join "\n", @sub;
            @sub = ();
            @seen{qw(begin end)} = (0,0);
        }
    }

    return @subs;
}

sub _write_begin {
    my $self = shift;

    my $INDENT = substr($self->{INDENT}, 0, length($self->{INDENT})-1);

    $self->_subst_makecode('begin');
    $self->{Data}{begin} =~ s/(\$INDENT)/$1/eego;
    $self->_do_verbose("\n", File::Basename::basename($self->{Config}{Build_PL}), " written:\n", 2);
    $self->_do_verbose('-' x ($self->{Config}{Build_PL_Length} + 9), "\n", 2);
    $self->_do_verbose($self->{Data}{begin}, 2);

    print $self->{Data}{begin};
}

sub _write_args {
    my $self = shift;

    my $arg;
    my $regex = '$chunk =~ /=> \{/';

    if (@{$self->{make_code}{args}{begin}||[]}) {
        foreach my $codechunk (@{$self->{make_code}{args}{begin}}) {
            if (ref $codechunk eq 'ARRAY') {
                foreach my $code (@$codechunk) {
                    $self->_do_verbose("$self->{INDENT}$code\n", 2);
                    print "$self->{INDENT}$code\n";
                }
            } else {
                $self->_do_verbose("$self->{INDENT}$codechunk\n", 2);
                print "$self->{INDENT}$codechunk\n";
            }
        }
    }

    foreach my $chunk (@{$self->{buildargs_dumped}}) {
        # Hash/Array output
        if ($chunk =~ /=> [\{\[]/) {

            # Remove redundant parentheses
            $chunk =~ s/^\{.*?\n(.*(?{ $regex ? '\}' : '\]' }))\s+\}\s+$/$1/os;

            # One element per each line
            my @lines;
            push @lines, $1 while $chunk =~ s/^(.*?\n)(.*)$/$2/s;

            # Gather whitespace up to hash key in order
            # to recreate native Dump() indentation.
            my ($whitespace) = $lines[0] =~ /^(\s+)(\w+)/;
            $arg = $2;
            my $shorten = length($whitespace);

            foreach (my $i = 0; $i < @lines; $i++) {
                my $line = $lines[$i];
                chomp $line;
                # Remove additional whitespace
                $line =~ s/^\s{$shorten}(.*)$/$1/o;

                # Quote sub hash keys
                $line =~ s/^(\s+)([\w:]+)/$1'$2'/ if $line =~ /^\s+/;

                # Add comma where appropriate (version numbers, parentheses, brackets)
                $line .= ',' if $line =~ /[\d+ \} \]] $/x;

                # (De)quotify numbers, variables & code bits
                $line =~ s/' \\? ( \d | [\\ \/ \( \) \$ \@ \%]+ \w+) '/$1/gx;
                $self->_quotify(\$line) if $line =~ /\(/;

                # Add comma to dequotified key/value pairs
                my $comma   = ',' if $line =~ /['"](?!,)$/ && $#lines - $i != 1;
                   $comma ||= '';

                # Construct line output
                my $output = "$self->{INDENT}$line$comma";

                # Add adhering comments at end of array/hash
                $output .= ($i == $#lines && defined $self->{make_comments}{$arg})
                  ? "$self->{make_comments}{$arg}\n"
                  : "\n";

                # Output line
                $self->_do_verbose($output, 2);
                print $output;
            }
        # String output
        } else {
            chomp $chunk;
            # Remove redundant parentheses
            $chunk =~ s/^\{\s+(.*?)\s+\}$/$1/sx;

            # (De)quotify numbers, variables & code bits
            $chunk =~ s/' \\? ( \d | [\\ \/ \( \) \$ \@ \%]+ \w+ ) '/$1/gx;
            $self->_quotify(\$chunk) if $chunk =~ /\(/;

            # Extract argument (key)
            ($arg) = $chunk =~ /^\s*(\w+)/;

            # Construct line output & add adhering comment
            my $output = "$self->{INDENT}$chunk,";
            $output .= $self->{make_comments}{$arg} if defined $self->{make_comments}{$arg};

            # Output key/value pair
            $self->_do_verbose("$output\n", 2);
            print "$output\n";
        }

        no warnings 'uninitialized';
        my @args;

        if ($self->{make_code}{args}{$arg}) {
            @args = ();
            foreach my $arg (@{$self->{make_code}{args}{$arg}}) {
                if (ref $arg eq 'ARRAY') {
                    push @args, @$arg;
                } else {
                    push @args, $arg;
                }
            }

            foreach $arg (@args) {
                next unless $arg;

                $arg .= ',' unless $arg =~ /^\#/;

                $self->_do_verbose("$self->{INDENT}$arg\n", 2);
                print "$self->{INDENT}$arg\n";
            }
        }
    }
}

sub _quotify {
    my ($self, $string) = @_;

    # Removing single-quotes and escaping backslashes
    $$string =~ s/(=>\s+?)'/$1/;
    $$string =~ s/',?$//;
    $$string =~ s/\\'/'/g; 

    # Double-quoting $(NAME) variables
    if ($$string =~ /\$\(/) {
        $$string =~ s/(=>\s+?)(.*)/$1"$2"/;
    }
}

sub _write_end {
    my $self = shift;

    my $INDENT = substr($self->{INDENT}, 0, length($self->{INDENT})-1);

    $self->_subst_makecode('end');
    $self->{Data}{end} =~ s/(\$INDENT)/$1/eego;
    $self->_do_verbose($self->{Data}{end}, 2);

    print $self->{Data}{end};
}

sub _subst_makecode {
    my ($self, $section) = @_;

    $self->{make_code}{$section} ||= '';

    $self->{make_code}{$section} =~ /\w/
      ? $self->{Data}{$section} =~ s/\$MAKECODE/$self->{make_code}{$section}/o
      : $self->{Data}{$section} =~ s/\n\$MAKECODE\n//o;
}

sub _add_to_manifest {
    my $self = shift;

    my $fh = IO::File->new($self->{Config}{MANIFEST}, '<')
      or die "Can't open $self->{Config}{MANIFEST}: $!\n";
    my @manifest = <$fh>;
    $fh->close;

    my $build_pl = File::Basename::basename($self->{Config}{Build_PL});

    unless (grep { /^$build_pl\s+$/o } @manifest) {
        unshift @manifest, "$build_pl\n";

        $fh = IO::File->new($self->{Config}{MANIFEST}, '>')
          or die "Can't open $self->{Config}{MANIFEST}: $!\n";
        print {$fh} sort @manifest;
        $fh->close;

        $self->_do_verbose(LEADCHAR."Added to $self->{Config}{MANIFEST}: $self->{Config}{Build_PL}\n");
    }
}

sub _show_summary {
    my $self = shift;

    my @summary = (
        [ 'Succeeded',       'succeeded'      ],
        [ 'Skipped',         'skipped'        ],
        [ 'Failed',          'failed'         ],
        [ 'Method: parse',   'method_parse'   ],
        [ 'Method: execute', 'method_execute' ],
    );

    local $" = "\n";

    foreach my $item (@summary) {
        next unless @{$self->{summary}{$item->[1]}||[]};

        $self->_do_verbose("$item->[0]\n");
        $self->_do_verbose('-' x length($item->[0]), "\n");
        $self->_do_verbose("@{$self->{summary}{$item->[1]}}\n\n");
    }

    my $howmany = @{$self->{summary}->{succeeded}};

    print "Processed $howmany directories\n";
}

sub _do_verbose {
    my $self = shift;

    my $level = $_[-1] =~ /^\d$/ ? pop : 1;

    if (($self->{Config}{Verbose} && $level == 1)
      || ($self->{Config}{Verbose} == 2 && $level == 2)) {
        print STDOUT @_;
    }
}

sub _debug {
    my $self = shift;

    if ($self->{Config}{Debug}) {
        pop and my $no_wait = 1 if $_[-1] eq 'no_wait';
        warn @_;
        warn "Press [enter] to continue...\n" 
          and <STDIN> unless $no_wait;
    }
}

1;
__DATA__

# argument conversion 
-
NAME                  module_name
DISTNAME              dist_name
ABSTRACT              dist_abstract
AUTHOR                dist_author
VERSION               dist_version
VERSION_FROM          dist_version_from
PREREQ_PM             requires
PL_FILES              PL_files
PM                    pm_files
MAN1PODS              pod_files
XS                    xs_files
INC                   include_dirs
INSTALLDIRS           installdirs
DESTDIR               destdir
CCFLAGS               extra_compiler_flags
EXTRA_META            meta_add
SIGN                  sign
LICENSE               license
clean.FILES           @add_to_cleanup

# default arguments 
-
#build_requires       HASH
#recommends           HASH
#conflicts            HASH
license               unknown
create_readme         1
create_makefile_pl    traditional

# sorting order 
-
module_name
dist_name
dist_abstract
dist_author
dist_version
dist_version_from
requires
build_requires
recommends
conflicts
PL_files
pm_files
pod_files
xs_files
include_dirs
installdirs
destdir
add_to_cleanup
extra_compiler_flags
meta_add
sign
license
create_readme
create_makefile_pl

# begin code 
-
use Module::Build;

$MAKECODE

my $build = Module::Build->new
$INDENT(
# end code 
-
$INDENT);

$build->create_build_script;

$MAKECODE

__END__

=head1 NAME

Module::Build::Convert - Makefile.PL to Build.PL converter

=head1 SYNOPSIS

 use Module::Build::Convert;

 # example arguments (empty %args is sufficient too)
 %args = (Path => '/path/to/perl/distribution(s)',
          Verbose => 2,
          Use_Native_Order => 1,
          Len_Indent => 4);

 $make = Module::Build::Convert->new(%args);
 $make->convert;

=head1 DESCRIPTION

C<ExtUtils::MakeMaker> has been a de-facto standard for the common distribution of Perl
modules; C<Module::Build> is expected to supersede C<ExtUtils::MakeMaker> in some time
(part of the Perl core as of 5.9.4).

The transition takes place slowly, as the converting process manually achieved
is yet an uncommon practice. The Module::Build::Convert F<Makefile.PL> parser is
intended to ease the transition process.

=head1 CONSTRUCTOR

=head2 new

Options:

=over 4

=item * C<Path>

Path to a Perl distribution. May point to a single distribution
directory or to one containing more than one distribution.
Default: C<''>

=item * C<Makefile_PL>

Filename of the Makefile script. Default: F<Makefile.PL>

=item * C<Build_PL>

Filename of the Build script. Default: F<Build.PL>

=item * C<MANIFEST>

Filename of the MANIFEST file. Default: F<MANIFEST>

=item * C<RC>

Filename of the RC file. Default: F<.make2buildrc>

=item * C<Dont_Overwrite_Auto>

If a Build.PL already exists, output a notification and ask whether it 
should be overwritten.
Default: 1

=item * C<Create_RC>

Create a RC file in the homedir of the current user.
Default: 0

=item * C<Parse_PPI>

Parse the Makefile.PL in the L<PPI> Parser mode.
Default: 0

=item * C<Exec_Makefile>

Execute the Makefile.PL via C<'do Makefile.PL'>.
Default: 0

=item * C<Verbose>

Verbose mode. If set to 1, overridden defaults and skipped arguments
are printed while converting; if set to 2, output of C<Verbose = 1> and
created Build script will be printed. May be set via the make2build 
switches C<-v> (mode 1) and C<-vv> (mode 2). Default: 0

=item * C<Debug>

Rudimentary debug facility for examining the parsing process.
Default: 0

=item * C<Process_Code>

Process code embedded within the arguments list.
Default: 0

=item * C<Use_Native_Order>

Native sorting order. If set to 1, the native sorting order of
the Makefile arguments will be tried to preserve; it's equal to
using the make2build switch C<-n>. Default: 0

=item * C<Len_Indent>

Indentation (character width). May be set via the make2build
switch C<-l>. Default: 3

=item * C<DD_Indent>

C<Data::Dumper> indendation mode. Mode 0 will be disregarded in favor
of 2. Default: 2

=item * C<DD_Sortkeys>

C<Data::Dumper> sort keys. Default: 1

=back

=head1 METHODS

=head2 convert

Parses the F<Makefile.PL>'s C<WriteMakefile()> arguments and converts them
to C<Module::Build> equivalents; subsequently the according F<Build.PL>
is created. Takes no arguments.

=head1 DATA SECTION

=head2 Argument conversion

C<ExtUtils::MakeMaker> arguments followed by their C<Module::Build> equivalents.
Converted data structures preserve their native structure,
that is, C<HASH> -> C<HASH>, etc.

 NAME                  module_name
 DISTNAME              dist_name
 ABSTRACT              dist_abstract
 AUTHOR                dist_author
 VERSION               dist_version
 VERSION_FROM          dist_version_from
 PREREQ_PM             requires
 PL_FILES              PL_files
 PM                    pm_files
 MAN1PODS              pod_files
 XS                    xs_files
 INC                   include_dirs
 INSTALLDIRS           installdirs
 DESTDIR               destdir
 CCFLAGS               extra_compiler_flags
 EXTRA_META            meta_add
 SIGN                  sign
 LICENSE               license
 clean.FILES           @add_to_cleanup

=head2 Default arguments

C<Module::Build> default arguments may be specified as key/value pairs. 
Arguments attached to multidimensional structures are unsupported.

 #build_requires       HASH
 #recommends           HASH
 #conflicts            HASH
 license               unknown
 create_readme         1
 create_makefile_pl    traditional

Value may be either a string or of type C<SCALAR, ARRAY, HASH>.

=head2 Sorting order

C<Module::Build> arguments are sorted as enlisted herein. Additional arguments,
that don't occur herein, are lower prioritized and will be inserted in
unsorted order after preceedingly sorted arguments.

 module_name
 dist_name
 dist_abstract
 dist_author
 dist_version
 dist_version_from
 requires
 build_requires
 recommends
 conflicts
 PL_files
 pm_files
 pod_files
 xs_files
 include_dirs
 installdirs
 destdir
 add_to_cleanup
 extra_compiler_flags
 meta_add
 sign
 license
 create_readme
 create_makefile_pl

=head2 Begin code

Code that preceeds converted C<Module::Build> arguments.

 use strict;
 use warnings;

 use Module::Build;

 $MAKECODE

 my $b = Module::Build->new
 $INDENT(

=head2 End code

Code that follows converted C<Module::Build> arguments.

 $INDENT);

 $b->create_build_script;

 $MAKECODE

=head1 INTERNALS

=head2 co-opting C<WriteMakefile()>

This behavior is no longer the default way to receive WriteMakefile()'s
arguments; the Makefile.PL is now statically parsed unless one forces
manually the co-opting of WriteMakefile().

In order to convert arguments, a typeglob from C<WriteMakefile()> to an
internal sub will be set; subsequently Makefile.PL will be executed and the
arguments are then accessible to the internal sub.

=head2 Data::Dumper

Converted C<ExtUtils::MakeMaker> arguments will be dumped by
C<Data::Dumper's> C<Dump()> and are then furtherly processed.

=head1 BUGS & CAVEATS

C<Module::Build::Convert> should be considered experimental as the parsing
of the Makefile.PL doesn't necessarily return valid arguments, especially for
Makefiles with bad or even worse, missing intendation.

The parsing process may sometimes hang with or without warnings in such cases.
Debugging by using the appropriate option/switch (see CONSTRUCTOR/new) may reveal
the root cause.

=head1 SEE ALSO

L<http://www.makemaker.org>, L<ExtUtils::MakeMaker>, L<Module::Build>,
L<http://www.makemaker.org/wiki/index.cgi?ModuleBuildConversionGuide>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
