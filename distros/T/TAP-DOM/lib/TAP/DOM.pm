package TAP::DOM;
# git description: v1.000-7-g37bf7ee

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: TAP as Document Object Model.
$TAP::DOM::VERSION = '1.001';
use 5.006;
use strict;
use warnings;

use TAP::DOM::Entry;
use TAP::DOM::Summary;
use TAP::DOM::DocumentData;
use TAP::DOM::Config;
use TAP::Parser;
use TAP::Parser::Aggregator;
use YAML::Syck;
use Data::Dumper;

our $IS_PLAN      = 1;
our $IS_OK        = 2;
our $IS_TEST      = 4;
our $IS_COMMENT   = 8;
our $IS_UNKNOWN   = 16;
our $IS_ACTUAL_OK = 32;
our $IS_VERSION   = 64;
our $IS_PRAGMA    = 128;
our $IS_UNPLANNED = 256;
our $IS_BAILOUT   = 512;
our $IS_YAML      = 1024;
our $HAS_SKIP     = 2048;
our $HAS_TODO     = 4096;

our @tap_dom_args = (qw(ignore
                        ignorelines
                        dontignorelines
                        ignoreunknown
                        usebitsets
                        sparse
                        disable_global_kv_data
                        put_dangling_kv_data_under_lazy_plan
                        document_data_prefix
                        document_data_ignore
                        preprocess_ignorelines
                        preprocess_tap
                        noempty_tap
                        utf8
                        lowercase_fieldnames
                        lowercase_fieldvalues
                        trim_fieldvalues
                        normalize
                     ));

use parent 'Exporter';
our @EXPORT_OK = qw( $IS_PLAN
                     $IS_OK
                     $IS_TEST
                     $IS_COMMENT
                     $IS_UNKNOWN
                     $IS_ACTUAL_OK
                     $IS_VERSION
                     $IS_PRAGMA
                     $IS_UNPLANNED
                     $IS_BAILOUT
                     $IS_YAML
                     $HAS_SKIP
                     $HAS_TODO
                  );
our %EXPORT_TAGS = (constants => [ qw( $IS_PLAN
                                       $IS_OK
                                       $IS_TEST
                                       $IS_COMMENT
                                       $IS_UNKNOWN
                                       $IS_ACTUAL_OK
                                       $IS_VERSION
                                       $IS_PRAGMA
                                       $IS_UNPLANNED
                                       $IS_BAILOUT
                                       $IS_YAML
                                       $HAS_SKIP
                                       $HAS_TODO
                                    ) ] );

our %mnemonic = (
  severity => {
    1 => 'ok',
    2 => 'ok_todo',
    3 => 'ok_skip',
    4 => 'notok_todo',
    5 => 'notok',
    6 => 'notok_skip', # forbidden TAP semantic, should never happen
  },
);

# TAP severity level definition:
#
# |--------+---------------+----------+--------------+----------+------------+----------|
# | *type* |         is_ok | has_todo | is_actual_ok | has_skip | *mnemonic* | *tapcon* |
# |--------+---------------+----------+--------------+----------+------------+----------|
# | plan   |         undef |    undef |        undef |        1 | ok_skip    |        3 |
# |--------+---------------+----------+--------------+----------+------------+----------|
# | test   |             1 |        0 |            0 |        0 | ok         |        1 |
# | test   |             1 |        1 |            1 |        0 | ok_todo    |        2 |
# | test   |             1 |        0 |            0 |        1 | ok_skip    |        3 |
# | test   |             1 |        1 |            0 |        0 | notok_todo |        4 |
# | test   |             0 |        0 |            0 |        0 | notok      |        5 |
# | test   |             0 |        0 |            0 |        1 | notok_skip |        6 |
# |--------+---------------+----------+--------------+----------+------------+----------|
# |        |               |          |              |          | missing    |        0 |
# |--------+---------------+----------+--------------+----------+------------+----------|
# | *type* |       *value* |          |              |          |            |          |
# |--------+---------------+----------+--------------+----------+------------+----------|
# | pragma | +tapdom_error |          |              |          | notok      |        5 |
# |--------+---------------+----------+--------------+----------+------------+----------|

our $severity = {};
#
#          {type} {is_ok} {has_todo} {is_actual_ok} {has_skip} = $severity;
#
$severity->{plan}     {0}        {0}            {0}        {1} = 3; # ok_skip
$severity->{test}     {1}        {0}            {0}        {0} = 1; # ok
$severity->{test}     {1}        {1}            {1}        {0} = 2; # ok_todo
$severity->{test}     {1}        {0}            {0}        {1} = 3; # ok_skip
$severity->{test}     {1}        {1}            {0}        {0} = 4; # notok_todo
$severity->{test}     {0}        {0}            {0}        {0} = 5; # notok
$severity->{test}     {0}        {0}            {0}        {1} = 6; # notok_skip

our $obvious_tap_line = qr/(1\.\.|ok\s|not\s+ok\s|#|\s|tap\s+version|pragma|Bail out!)/i;

our $noempty_tap = "pragma +tapdom_error\n# document was empty";

use Class::XSAccessor
    chained     => 1,
    accessors   => [qw( plan
                        lines
                        pragmas
                        tests_planned
                        tests_run
                        version
                        is_good_plan
                        skip_all
                        start_time
                        end_time
                        has_problems
                        exit
                        parse_errors
                        parse_errors_msgs
                        summary
                        tapdom_config
                        document_data
                     )];

sub _capture_group {
    my ($s, $n) = @_; substr($s, $-[$n], $+[$n] - $-[$n]);
}

sub normalize_tap_line {
  my ($line) = @_;

  return $line unless $line =~ m/^(not\s+)?(ok)\s+/;

  $line =~ s{^(not\s)?\s*(ok)\s+(\d+\s)?\s*(-\s+)?\s*}{($1//'').$2.' '}e;
  $line =~ s/['"]//g;
  $line =~ s/\\(?!#\s*(todo|skip)\b)//gi;
  $line =~ s/\s*(?<!\\)#\s*(todo|skip)\b/' # '.uc($1)/ei;
  $line =~ s/^\s+//g;
  $line =~ s/\s+$//g;

  return $line;
}

# Optimize the TAP text before parsing it.
sub preprocess_ignorelines {
    my %args = @_;

    if ($args{tap}) {

        if (my $ignorelines = $args{ignorelines}) {
            my $dontignorelines = $args{dontignorelines};
            my $tap = $args{tap};
            if ($dontignorelines) {
                # HIGHLY EXPERIMENTAL!
                #
                # We convert the 'dontignorelines' regex into a negative-lookahead
                # condition and prepend it before the 'ignorelines'.
                #
                # Why? Because we want to utilize the cleanup in one single
                # operation as fast as the regex engine can do it.
                my $re_dontignorelines = $dontignorelines ? "(?!$dontignorelines)" : '';
                my $re_filter = qr/^$re_dontignorelines$ignorelines.*[\r\n]*/m; # the /m scope needs to be here!
                $tap =~ s/$re_filter//g;
            } else {
                $tap =~ s/^$ignorelines.*[\r\n]*//mg;
            }
            $args{tap} = $tap;
            delete $args{ignorelines}; # don't try it again during parsing later
        }
    }

    return %args
}

# Filter away obvious non-TAP lines before parsing it.
sub preprocess_tap {
    my %args = @_;

    if ($args{tap}) {
      my $tap = $args{tap};
        $tap =~ s/^(?!$obvious_tap_line).*[\r\n]*//mg;
        $args{tap} = $tap;
    }

    return %args
}

# Mark empty TAP with replacement lines
sub noempty_tap {
    my %args = @_;

    if (defined($args{tap}) and $args{tap} eq '') {
      $args{tap} = $noempty_tap;
    }
    elsif (defined($args{source}) and -z $args{source}) {
      $args{tap} = $noempty_tap;
      delete $args{source};
    }

    return %args
}

# Assume TAP is UTF-8 and filter out forbidden characters.
#
# Convert illegal chars into Unicode 'REPLACEMENT CHARACTER'
# (\N{U+FFFD} ... i.e. diamond with question mark in it).
#
# For more info see:
#
#  - https://stackoverflow.com/a/2656433/1342345
#  - https://metacpan.org/pod/Encode#FB_DEFAULT
#  - https://en.wikipedia.org/wiki/Specials_(Unicode_block)#Replacement_character
#
# Additionall convert \0 as it's not covered by Encode::decode()
# but is still illegal for some tools.
sub utf8_tap {
    my %args = @_;

    if ($args{source}) {
      local $/;
      my $F;
      if (ref($args{source}) eq 'GLOB') {
        $F = $args{source};
      } else {
        open $F, '<', $args{source};
      }
      $args{tap} = <$F>;
      close $F;
      delete $args{source};
    }

    if ($args{tap}) {
      require Encode;
      $args{tap} = Encode::decode('UTF-8', $args{tap});
      $args{tap} =~ s/\0/\N{U+FFFD}/g;
      delete $args{utf8}; # don't try it again during parsing later
    }
    return %args
}

sub new {
        # hash or hash ref
        my $class = shift;
        my %args = @_ == 1 ? %{$_[0]} : @_;

        my @lines;
        my $plan;
        my $version;
        my @pragmas;
        my $bailout;
        my %document_data;
        my %dangling_kv_data;

        %args = preprocess_ignorelines(%args) if $args{preprocess_ignorelines};
        %args = preprocess_tap(%args)         if $args{preprocess_tap};
        %args = noempty_tap(%args)            if $args{noempty_tap};
        %args = utf8_tap(%args)               if $args{utf8};

        my %IGNORE      = map { $_ => 1 } @{$args{ignore}};
        my $IGNORELINES = $args{ignorelines};
        my $DONTIGNORELINES = $args{dontignorelines};
        my $IGNOREUNKNOWN = $args{ignoreunknown};
        my $USEBITSETS  = $args{usebitsets};
        my $SPARSE  = $args{sparse};
        my $DISABLE_GLOBAL_KV_DATA  = $args{disable_global_kv_data};
        my $PUT_DANGLING_KV_DATA_UNDER_LAZY_PLAN  = $args{put_dangling_kv_data_under_lazy_plan};
        my $DOC_DATA_PREFIX = $args{document_data_prefix} || 'Test-';
        my $DOC_DATA_IGNORE = $args{document_data_ignore};
        my $LOWERCASE_FIELDNAMES = $args{lowercase_fieldnames};
        my $LOWERCASE_FIELDVALUES = $args{lowercase_fieldvalues};
        my $TRIM_FIELDVALUES = $args{trim_fieldvalues};
        my $NOEMPTY_TAP = $args{noempty_tap};
        my $NORMALIZE = $args{normalize};
        delete $args{ignore};
        delete $args{ignorelines};
        delete $args{dontignorelines};
        delete $args{ignoreunknown};
        delete $args{usebitsets};
        delete $args{sparse};
        delete $args{disable_global_kv_data};
        delete $args{put_dangling_kv_data_under_lazy_plan};
        delete $args{document_data_prefix};
        delete $args{document_data_ignore};
        delete $args{preprocess_ignorelines};
        delete $args{preprocess_tap};
        delete $args{noempty_tap};
        delete $args{utf8};
        delete $args{lowercase_fieldnames};
        delete $args{lowercase_fieldvalues};
        delete $args{trim_fieldvalues};
        delete $args{normalize};

        my $document_data_regex = qr/^#\s*$DOC_DATA_PREFIX([^:]+)\s*:\s*(.*)$/;
        my $document_data_ignore = defined($DOC_DATA_IGNORE) ? qr/$DOC_DATA_IGNORE/ : undef;

        my $parser = TAP::Parser->new( { %args } );

        my $aggregate = TAP::Parser::Aggregator->new;
        $aggregate->start;

        my $count_tap_lines = 0;
        my $found_pragma_tapdom_error = 0;
        while ( my $result = $parser->next ) {
                no strict 'refs';

                next if $IGNORELINES && $result->raw =~ m/$IGNORELINES/ && !($DONTIGNORELINES && $result->raw =~ m/$DONTIGNORELINES/);
                next if $IGNOREUNKNOWN and $result->is_unknown;

                my $entry = TAP::DOM::Entry->new;
                $entry->{is_has} = 0 if $USEBITSETS;

                # test info
                foreach (qw(type raw as_string )) {
                        $entry->{$_} = $result->$_ unless $IGNORE{$_};
                }
                $entry->{normalized}  = $result->is_test ? normalize_tap_line($result->raw) : $result->raw;

                if ($result->is_test) {
                        foreach (qw(directive explanation number description )) {
                                $entry->{$_} = $result->$_ unless $IGNORE{$_};
                        }
                        foreach (qw(is_ok is_unplanned )) {
                                if ($USEBITSETS) {
                                        $entry->{is_has} |= $result->$_ ? ${uc $_} : 0 unless $IGNORE{$_};
                                } elsif ($SPARSE) {
                                        # don't set 'false' fields at all in sparse mode
                                        $entry->{$_} = 1 if $result->$_ and not $IGNORE{$_};
                                } else {
                                        $entry->{$_} = $result->$_ ? 1 : 0 unless $IGNORE{$_};
                                }
                        }
                }

                # plan
                if ($result->is_plan) {
                  $plan = $result->as_string;
                  foreach (qw(directive explanation)) {
                          $entry->{$_} = $result->$_ unless $IGNORE{$_};
                  }

                  # save Dangling kv_data to plan entry. The situation
                  # that we already collected kv_data but haven't got
                  # a plan yet should only happen in documents with
                  # lazy plans (plan at the end).
                  if ($PUT_DANGLING_KV_DATA_UNDER_LAZY_PLAN and keys %dangling_kv_data) {
                    $entry->{kv_data}{$_} = $dangling_kv_data{$_} foreach keys %dangling_kv_data;
                  }
                }

                # meta info
                foreach ((qw(has_skip has_todo))) {
                        if ($USEBITSETS) {
                                $entry->{is_has} |= $result->$_ ? ${uc $_} : 0 unless $IGNORE{$_};
                        } elsif ($SPARSE) {
                                # don't set 'false' fields at all in sparse mode
                                $entry->{$_} = 1 if $result->$_ and not $IGNORE{$_};
                        } else {
                                $entry->{$_} = $result->$_ ? 1 : 0 unless $IGNORE{$_};
                        }
                }
                # Idea:
                # use constants
                # map to constants
                # then loop
                foreach (qw( is_pragma is_comment is_bailout is_plan
                             is_version is_yaml is_unknown is_test))
                {
                        if ($USEBITSETS) {
                                $entry->{is_has} |= $result->$_ ? ${uc $_} : 0 unless $IGNORE{$_};
                        } elsif ($SPARSE) {
                                # don't set 'false' fields at all in sparse mode
                                $entry->{$_} = 1 if $result->$_ and not $IGNORE{$_};
                        } else {
                                $entry->{$_} = $result->$_ ? 1 : 0 unless $IGNORE{$_};
                        }
                }
                if (! $IGNORE{is_actual_ok}) {
                        # XXX:
                        # I think it's confusing when the value of
                        # "is_actual_ok" only has a meaning when
                        # "has_todo" is true.
                        # This makes it difficult to evaluate later.
                        # But it's aligned with TAP::Parser
                        # which also sets this only on "has_todo".
                        #
                        # Maybe the problem is a general philosophical one
                        # in TAP::DOM to always have each hashkey existing.
                        # Hmmm...
                        my $is_actual_ok = ($result->has_todo && $result->is_actual_ok) ? 1 : 0;
                        if ($USEBITSETS) {
                                $entry->{is_has} |= $is_actual_ok ? $IS_ACTUAL_OK : 0;
                        } elsif ($SPARSE) {
                                # don't set 'false' fields at all in sparse mode
                                $entry->{is_actual_ok} = 1 if $is_actual_ok;
                        } else {
                                $entry->{is_actual_ok} = $is_actual_ok;
                        }
                }
                $entry->{data}         = $result->data if $result->is_yaml && !$IGNORE{data};

                if ($result->is_comment and $result->as_string =~ $document_data_regex)
                {{ # extra block for 'last'
                        # we can't use $1, $2 because the regex could contain configured other groups
                        my ($key, $value) = (_capture_group($result->as_string, -2), _capture_group($result->as_string, -1));
                        $key =~ s/^\s+//; # strip leading  whitespace
                        $key =~ s/\s+$//; # strip trailing whitespace

                        # optional lowercase
                        $key   = lc $key   if $LOWERCASE_FIELDNAMES;
                        $value = lc $value if $LOWERCASE_FIELDVALUES;

                        # optional value trimming
                        $value =~ s/\s+$// if $TRIM_FIELDVALUES; # there can be no leading whitespace

                        # skip this field according to regex
                        last if $DOC_DATA_IGNORE and $document_data_ignore and $key =~ $document_data_ignore;

                        # Store "# Test-key: value" entries also as
                        # 'kv_data' under their parent line.
                        # That line should be a test or a plan line, so that its
                        # place (or "data path") is structurally always the same.
                        if ($lines[-1]->is_test or $lines[-1]->is_plan or $lines[-1]->is_pragma) {
                            $lines[-1]->{kv_data}{$key} = $value;
                        } else {
                            if (!$plan) {
                              # We haven't got a plan yet, so that
                              # kv_data entry would get lost. As we
                              # might still get a lazy plan at end
                              # of document, so we save it up for
                              # that potential plan entry.
                              $dangling_kv_data{$key} = $value;
                            }
                        }
                        $document_data{$key} = $value unless $lines[-1]->is_test && $DISABLE_GLOBAL_KV_DATA;
                }}

                # calculate severity
                if ($entry->{is_test} or $entry->{is_plan}) {
                  no warnings 'uninitialized';
                  $count_tap_lines++;
                  $entry->{severity} = $severity
                    ->{$entry->{type}}
                    ->{$entry->{is_ok}||0}
                    ->{$entry->{has_todo}||0}
                    ->{$entry->{is_actual_ok}||0}
                    ->{$entry->{has_skip}||0};
                }

                if ($entry->{is_pragma} or $entry->{is_unknown}) {
                  no warnings 'uninitialized';
                  if ($entry->{raw} =~ /^pragma\s+\+tapdom_error\s*$/) {
                    $found_pragma_tapdom_error=1;
                    $entry->{severity}   = 5;
                    $entry->{is_pragma}  = 1;
                    $entry->{type}       = 'pragma';
                    delete $entry->{is_unknown};
                  } else {
                    $entry->{severity} = 0;
                  }
                }
                $entry->{severity} = 0 if not defined $entry->{severity};

                # yaml and comments are taken as children of the line before
                if ($result->is_yaml or $result->is_comment and @lines)
                {
                        push @{ $lines[-1]->{_children} }, $entry;
                }
                else
                {
                        push @lines, $entry;
                }
        }
        @pragmas = $parser->pragmas;

        if (!$count_tap_lines and !$found_pragma_tapdom_error and $NOEMPTY_TAP) {
          # pragma +tapdom_error
          my $error_entry = TAP::DOM::Entry->new(
            ($SPARSE ? () : (
              'is_version'   => 0,
              'is_plan'      => 0,
              'is_test'      => 0,
              'is_comment'   => 0,
              'is_yaml'      => 0,
              'is_unknown'   => 0,
              'is_bailout'   => 0,
              'is_actual_ok' => 0,
              'has_todo'     => 0,
              'has_skip'     => 0,
            )),
            'is_pragma'    => 1,
            'type'         => 'pragma',
            'raw'          => 'pragma +tapdom_error',
            'as_string'    => 'pragma +tapdom_error',
            'severity'     => 5,
          );
          $error_entry->{is_has} = $IS_PRAGMA if $USEBITSETS;
          foreach (qw(raw type as_string explanation)) { delete $error_entry->{$_} if $IGNORE{$_} }
          # pragma +tapdom_error
          my $error_comment = TAP::DOM::Entry->new(
            ($SPARSE ? () : (
              'is_version'   => 0,
              'is_plan'      => 0,
              'is_test'      => 0,
              'is_yaml'      => 0,
              'is_unknown'   => 0,
              'is_bailout'   => 0,
              'is_actual_ok' => 0,
              'is_pragma'    => 0,
              'has_todo'     => 0,
              'has_skip'     => 0,
            )),
            'is_comment'   => 1,
            'type'         => 'comment',
            'raw'          => '# no tap lines',
            'as_string'    => '# no tap lines',
            'severity'     => 0,
          );
          $error_comment->{is_has} = $IS_COMMENT if $USEBITSETS;
          foreach (qw(raw type as_string explanation)) { delete $error_comment->{$_} if $IGNORE{$_} }
          $error_entry->{_children} //= [];
          push @{$error_entry->{_children}}, $error_comment;
          push @lines, $error_entry;
          push @pragmas, 'tapdom_error';
        }

        $aggregate->add( main => $parser );
        $aggregate->stop;

        my $summary = TAP::DOM::Summary->new
         (
          failed          => scalar $aggregate->failed,
          parse_errors    => scalar $aggregate->parse_errors,
          planned         => scalar $aggregate->planned,
          passed          => scalar $aggregate->passed,
          skipped         => scalar $aggregate->skipped,
          todo            => scalar $aggregate->todo,
          todo_passed     => scalar $aggregate->todo_passed,
          wait            => scalar $aggregate->wait,
          exit            => scalar $aggregate->exit,
          elapsed         => $aggregate->elapsed,
          elapsed_timestr => $aggregate->elapsed_timestr,
          all_passed      => $aggregate->all_passed ? 1 : 0,
          status          => $aggregate->get_status,
          total           => $aggregate->total,
          has_problems    => $aggregate->has_problems ? 1 : 0,
          has_errors      => $aggregate->has_errors ? 1 : 0,
         );

        my $tapdom_config = TAP::DOM::Config->new
         (
          ignore                               => \%IGNORE,
          ignorelines                          => $IGNORELINES,
          dontignorelines                      => $DONTIGNORELINES,
          usebitsets                           => $USEBITSETS,
          sparse                               => $SPARSE,
          disable_global_kv_data               => $DISABLE_GLOBAL_KV_DATA,
          put_dangling_kv_data_under_lazy_plan => $PUT_DANGLING_KV_DATA_UNDER_LAZY_PLAN,
          document_data_prefix                 => $DOC_DATA_PREFIX,
          document_data_ignore                 => $DOC_DATA_IGNORE,
          lowercase_fieldnames                 => $LOWERCASE_FIELDNAMES,
          lowercase_fieldvalues                => $LOWERCASE_FIELDVALUES,
          trim_fieldvalues                     => $TRIM_FIELDVALUES,
          noempty_tap                          => $NOEMPTY_TAP,
         );

        my $document_data = TAP::DOM::DocumentData->new(%document_data);

        my $tapdata = {
                       plan          => $plan,
                       lines         => \@lines,
                       pragmas       => \@pragmas,
                       tests_planned => $parser->tests_planned,
                       tests_run     => $parser->tests_run,
                       version       => $parser->version,
                       is_good_plan  => $parser->is_good_plan,
                       skip_all      => $parser->skip_all,
                       start_time    => $parser->start_time,
                       end_time      => $parser->end_time,
                       has_problems  => $parser->has_problems,
                       exit          => $parser->exit,
                       parse_errors  => scalar $parser->parse_errors,
                       parse_errors_msgs  => [ $parser->parse_errors ],
                       summary       => $summary,
                       tapdom_config => $tapdom_config,
                       document_data => $document_data,
                      };
        return bless $tapdata, $class;
}

sub _entry_to_tapline
{
        my ($self, $entry) = @_;

        my %IGNORE = %{$self->{tapdom_config}{ignore}};

        my $tapline = "";

        # ok/notok test lines
        if ($entry->{is_test})
        {
                $tapline = join(" ",
                                # the original "NOT" is more difficult to reconstruct than it should...
                                ($entry->{has_todo}
                                 ? $entry->{is_actual_ok} ? () : "not"
                                 : $entry->{is_ok}        ? () : "not"),
                                "ok",
                                ($entry->{number} || ()),
                                ($entry->{description} || ()),
                                ($entry->{has_skip}   ? "# SKIP ".($entry->{explanation} || "")
                                 : $entry->{has_todo }? "# TODO ".($entry->{explanation} || "")
                                 : ()),
                               );
        }
        # pragmas and meta lines, but no version nor plan
        elsif ($entry->{is_pragma}  ||
               $entry->{is_comment} ||
               $entry->{is_bailout} ||
               $entry->{is_yaml})
        {
                $tapline = $IGNORE{raw} ? $entry->{as_string} : $entry->{raw}; # if "raw" was 'ignored' try "as_string"
        }
        return $tapline;
}

sub _lines_to_tap
{
        my ($self, $lines) = @_;

        my @taplines;
        foreach my $entry (@$lines)
        {
                my $tapline = $self->_entry_to_tapline($entry);
                push @taplines, $tapline if $tapline;
                push @taplines, $self->_lines_to_tap($entry->{_children}) if $entry->{_children};
        }
        return @taplines;
}

sub to_tap
{
    my ($self) = @_;

    my @taplines = $self->_lines_to_tap($self->{lines});
    unshift @taplines, $self->{plan};
    unshift @taplines, "TAP version ".$self->{version};

    return wantarray
      ? @taplines
      : join("\n", @taplines)."\n";
}

1; # End of TAP::DOM

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM - TAP as Document Object Model.

=head1 SYNOPSIS

 # Create a DOM from TAP
 use TAP::DOM;
 my $tapdom = TAP::DOM->new( tap => $tap ); # same options as TAP::Parser
 print Dumper($tapdom);
 
 # Recreate TAP from DOM
 my $tap2 = $tapdom->to_tap;

=head1 DESCRIPTION

The purpose of this module is

=over 4

=item A) to define a B<reliable> data structure (a DOM)

=item B) create a DOM from TAP

=item C) recreate TAP from a DOM

=back

That is useful when you want to analyze the TAP in detail with "data
exploration tools", like L<Data::DPath|Data::DPath>.

``Reliable'' means that this structure is kind of an API that will not
change, so your data tools can, well, rely on it.

=head1 STRUCTURE

The data structure is basically a nested hash/array structure with
keys named after the functions of TAP::Parser that you normally would
use to extract results.

See the TAP example file in C<t/some_tap.txt> and its corresponding
result structure in C<t/some_tap.dom>.

Here is a slightly commented and beautified excerpt of
C<t/some_tap.dom>. Due to it's beeing manually washed for readability
there might be errors in it, so for final reference, dump a DOM by
yourself.

 bless( {
  # general TAP stats:
  'version'       => 13,
  'plan'          => '1..6',
  'tests_planned' => 6
  'tests_run'     => 8,
  'is_good_plan'  => 0,
  'has_problems'  => 2,
  'skip_all'      => undef,
  'parse_errors'  => 1,
  'parse_errors_msgs'  => [
                      'Bad plan.  You planned 6 tests but ran 8.'
                     ],
  'pragmas'       => [
                      'strict'
                     ],
  'exit'          => 0,
  'start_time'    => '1236463400.25151',
  'end_time'      => '1236463400.25468',
  # the used TAP::DOM specific options to TAP::DOM->new():
  'tapdom_config' => {
                      'ignorelines' => qr/(?-xism:^## )/,
                      'usebitsets' => undef,
                      'ignore' => {}
                     },
  # summary according to TAP::Parser::Aggregator:
  'summary' => {
                 'status'          => 'FAIL',
                 'total'           => 8,
                 'passed'          => 6,
                 'failed'          => 2,
                 'all_passed'      => 0,
                 'skipped'         => 1,
                 'todo'            => 4,
                 'todo_passed'     => 2,
                 'parse_errors'    => 1,
                 'has_errors'      => 1,
                 'has_problems'    => 1,
                 'exit'            => 0,
                 'wait'            => 0
                 'elapsed'         => bless( [
                                              0,
                                              '0',
                                              0,
                                              0,
                                              0,
                                              0
                                             ], 'Benchmark' ),
                 'elapsed_timestr' => ' 0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)',
               },
  # all recognized TAP lines:
  'lines' => [
              {
               'is_actual_ok' => 0,
               'is_bailout'   => 0,
               'is_comment'   => 0,
               'is_plan'      => 0,
               'is_pragma'    => 0,
               'is_test'      => 0,
               'is_unknown'   => 0,
               'is_version'   => 1,                      # <---
               'is_yaml'      => 0,
               'has_skip'     => 0,
               'has_todo'     => 0,
               'severity'     => 0,
               'raw'          => 'TAP version 13'
               'as_string'    => 'TAP version 13',
              },
              {
                'is_actual_ok' => 0,
                'is_bailout'   => 0,
                'is_comment'   => 0,
                'is_plan'      => 1,                     # <---
                'is_pragma'    => 0,
                'is_test'      => 0,
                'is_unknown'   => 0,
                'is_version'   => 0,
                'is_yaml'      => 0,
                'has_skip'     => 0,
                'has_todo'     => 0,
                'severity'     => 0,
                'raw'          => '1..6'
                'as_string'    => '1..6',
              },
              {
                'is_actual_ok' => 0,
                'is_bailout'   => 0,
                'is_comment'   => 0,
                'is_ok'        => 1,                     # <---
                'is_plan'      => 0,
                'is_pragma'    => 0,
                'is_test'      => 1,                     # <---
                'is_unknown'   => 0,
                'is_unplanned' => 0,
                'is_version'   => 0,
                'is_yaml'      => 0,
                'has_skip'     => 0,
                'has_todo'     => 0,
                'number'       => '1',                   # <---
                'severity'     => 1,
                'type'         => 'test',
                'raw'          => 'ok 1 - use Data::DPath;'
                'as_string'    => 'ok 1 - use Data::DPath;',
                'description'  => '- use Data::DPath;',
                'directive'    => '',
                'explanation'  => '',
                '_children'    => [
                                   # ----- children are the subsequent comment/yaml lines -----
                                   {
                                     'is_actual_ok' => 0,
                                     'is_unknown'   => 0,
                                     'has_todo'     => 0,
                                     'is_bailout'   => 0,
                                     'is_pragma'    => 0,
                                     'is_version'   => 0,
                                     'is_comment'   => 0,
                                     'has_skip'     => 0,
                                     'is_test'      => 0,
                                     'is_yaml'      => 1,              # <---
                                     'is_plan'      => 0,
                                     'raw'          => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...'
                                     'as_string'    => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...',
                                     'data'         => [
                                                        {
                                                          'value' => '1',
                                                          'name' => 'Hash one'
                                                        },
                                                        {
                                                          'value' => '2',
                                                          'name' => 'Hash two'
                                                        }
                                                       ],
                                 }
                               ],
              },
              {
                'is_actual_ok' => 0,
                'is_bailout'   => 0,
                'is_comment'   => 0,
                'is_ok'        => 1,                     # <---
                'is_plan'      => 0,
                'is_pragma'    => 0,
                'is_test'      => 1,                     # <---
                'is_unknown'   => 0,
                'is_unplanned' => 0,
                'is_version'   => 0,
                'is_yaml'      => 0,
                'has_skip'     => 0,
                'has_todo'     => 0,
                'explanation'  => '',
                'number'       => '2',                   # <---
                'type'         => 'test',
                'description'  => '- KEYs + PARENT',
                'directive'    => '',
                'severity'     => 1,
                'raw'          => 'ok 2 - KEYs + PARENT'
                'as_string'    => 'ok 2 - KEYs + PARENT',
              },
              # etc., see the rest in t/some_tap.dom ...
             ],
 }, 'TAP::DOM')                                          # blessed

=head1 NESTED LINES

As you can see above, diagnostic lines (comment or yaml) are nested
into the line before under a key C<_children> which simply contains an
array of those comment/yaml line elements.

With this you can recognize where the diagnostic lines semantically
belong, i.e. to their I<parent> test line.

=head1 METHODS

=head2 new

Constructor which immediately triggers parsing the TAP via TAP::Parser
and returns a big data structure containing the extracted results.

=head3 Synopsis

 my $tap;
 {
   local $/; open (TAP, '<', 't/some_tap.txt') or die;
   $tap = <TAP>;
   close TAP;
 }
 my $tapdata = TAP::DOM->new (
   tap                                  => $tap
   disable_global_kv_data               => 1,
   put_dangling_kv_data_under_lazy_plan => 1,
   ignorelines                          => '(## |# Test-mymeta_)',
   dontignorelines                      => '# Test-mymeta_(tool1|tool2)_',
   ignoreunknown                        => 1,
   preprocess_ignorelines               => 1,
   preprocess_tap                       => 1,
   usebitsets                           => 0,
   sparse                               => 0,
   ignore                               => ['as_string'], # keep 'raw' which is the unmodified variant
   document_data_prefix                 => '(MyApp|Test)-',
   lowercase_fieldnames                 => 1,
   trim_fieldvalues                     => 1,
 );

=head3 Options

=over 4

=item ignore

Arrayref of fieldnames not to contain in generated TAP::DOM. For
example you can skip the C<as_string> field which is often a redundant
variant of C<raw>.

=item ignorelines

A regular expression describing lines to ignore.

Be careful to not screw up semantically relevant lines, like indented
YAML data.

The regex is internally prepended with a start-of-line C<^> anchor.

=item dontignorelines (EXPERIMENTAL!)

This is the whitelist of lines to B<not> being skipped when using the
C<ignore> blacklist.

The C<dontignorelines> feature is B<HIGHLY EXPERIMENTAL>, in
particular in combination with C<preprocess_ignorelines>.

Background: the preprocessing is done in a single regex operation for
speed reasons, and to do that the C<dontignorelines> regex is turned
into a I<zero-width negative-lookahead condition> and prepended before
the C<ignorelines> condition into a combined regex.

Without C<preprocess_ignorelines> it is a relatively harmless
additional condition during TAP line processing.

Survival tips:

=over 2

=item * have unit tests for your setup

=item * do not use C<^> anchors neither in C<ignorelines> nor in
C<dontignorelines> but rely on the implicitly prepended anchors.

=item * write both C<ignorelines> and C<dontignorelines> completely
describing from beginning of line (yet without the C<^> anchor).

=item * do not use it but define C<ignorelines> instead with your own
zero-width negative-lookaround conditions

=item * know the zero-width negative look-around conditions of your
use Perl version

=back

=item ignoreunknown

By default non-TAP lines are still part of the TAP::DOM (with
C<is_unknown=1> and most other entry fields set to C<undef>).

If you mix a lot of non-TAP lines with actual TAP lines then
this can lead to a huge TAP::DOM data structure.

With this option set to 1 the C<unknown> lines are skipped.

=item usebitsets

Instead of having a lot of long boolean fields like

 has_skip => 1
 has_todo => 0

you can encode all of them into a compact bitset

 is_has => $SOME_NUMERIC_REPRESENTATION

This field must be evaluated later with bit-comparison operators.

Originally meant as memory-saving mechanism it turned out not to be
worth the hazzle.

=item sparse

Only generate boolean fields if they are a true value. This results in
a much more condensed data structure but also means you can't check on
value C<0> but the absence of value C<1>.

The option has no effect when C<usebitsets> is used.

With the C<spare> option the actual line entries get restricted to
only actually true values like this:

  # ... (the initial part is same as above in chapter "STRUCTURE")
  'lines' => [
              {
               'is_version'   => 1,
               'severity'     => 0,
               'raw'          => 'TAP version 13'
               'as_string'    => 'TAP version 13',
              },
              {
                'is_plan'      => 1,
                'severity'     => 0,
                'raw'          => '1..6'
                'as_string'    => '1..6',
              },
              {
                'is_ok'        => 1,
                'is_test'      => 1,
                'number'       => '1',
                'severity'     => 1,
                'type'         => 'test',
                'raw'          => 'ok 1 - use Data::DPath;'
                'as_string'    => 'ok 1 - use Data::DPath;',
                'normalized'   => 'ok use Data::DPath;',
                'description'  => '- use Data::DPath;',
                'directive'    => '',
                'explanation'  => '',
                '_children'    => [
                                   # ----- children are the subsequent comment/yaml lines -----
                                   {
                                     'is_yaml'      => 1,
                                     'raw'          => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...'
                                     'as_string'    => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...',
                                     'data'         => [
                                                        {
                                                          'value' => '1',
                                                          'name' => 'Hash one'
                                                        },
                                                        {
                                                          'value' => '2',
                                                          'name' => 'Hash two'
                                                        }
                                                       ],
                                 }
                               ],
              },
              {
                'is_ok'        => 1,
                'is_test'      => 1,
                'explanation'  => '',
                'number'       => '2',
                'type'         => 'test',
                'description'  => '- KEYs + PARENT',
                'directive'    => '',
                'severity'     => 1,
                'raw'          => 'ok 2 - KEYs + PARENT'
                'as_string'    => 'ok 2 - KEYs + PARENT',
              },
              # etc., see the rest in t/some_tap.dom ...
             ],

=item disable_global_kv_data

Early TAP::DOM versions put all lines like

  # Test-foo: bar

into a global hash. Later these fields are placed as children under
their parent C<ok>/C<not ok> line but kept globally for backwards
compatibility. With this flag you can drop the redundant global hash.

But see also C<put_dangling_kv_data_under_lazy_plan>.

=item put_dangling_kv_data_under_lazy_plan

This addresses the situation what to do in case a key/value field from
a line

  # Test-foo: bar

appears without a parent C<ok>/C<not ok> line and the global kv_data
hash is disabled. When this option is set it's placed under the plan
as parent.

=item document_data_prefix

To interpret lines like

  # Test-foo: bar

the C<document_data_prefix> is by default set to C<Test-> so that a
key/value field

  foo => 'bar'

is generated. However, you can have a regular expression to capture
other or multiple different values as allowed prefixes.

=item document_data_ignore

This is another regex-based way to avoid generating particular
fields. This regex is matched against the already extracted keys, and
stops processing of this field for C<document_data> and C<kv_data>.

=item lowercase_fieldnames

If set to a true value all recognized fields are lowercased.

=item lowercase_fieldvalues

If set to a true value all recognized values are lowercased.

=item trim_fieldvalues

If set to a true value all field values are trimmed of trailing
whitespace. Note that fields don't have leading whitespace as it's
already consumed away after the fieldname separator colon C<:>.

=back

All other provided parameters are passed through to TAP::Parser, see
sections "HOW TO STRIP DETAILS" and "USING BITSETS". Usually the
options are just one of those:

  tap => $some_tap_string

or

  source => $test_file

But there are more, see L<TAP::Parser|TAP::Parser>.

=head2 to_tap

Called on a TAP::DOM object it returns a string that is TAP.

=head1 HOW TO STRIP DETAILS

You can make the DOM a bit more terse (i.e., less blown up) if you do
not need every detail.

=head2 Strip unneccessary TAP-DOM fields

For this provide the C<ignore> option to new(). It is an array ref
specifying keys that should not be contained in the TAP-DOM. Currently
supported are:

 has_todo
 has_skip
 directive
 as_string
 explanation
 description
 is_unplanned
 is_actual_ok
 is_bailout
 is_unknown
 is_version
 is_bailout
 is_comment
 is_pragma
 is_plan
 is_test
 is_yaml
 is_ok
 number
 type
 raw

Use it like this:

   $tapdom = TAP::DOM->new (tap    => $tap,
                            ignore => [ qw( raw as_string ) ],
                           );

=head2 Strip unneccessary lines

You can ignore complete lines from the input TAP as if they weren't
existing by setting a regular expression in C<ignorelines>. Of
course you can break the TAP with this, so usually you only apply this
to non-TAP lines or diagnostics you are not interested in.

My primary use-case is TAP with large parts of logfiles included with
a prefixed "## " just for dual-using the TAP also as an archive of the
log. When evaluating the TAP later I leave those log lines out because
they only blow up the memory for the TAP-DOM:

 $tapdom = TAP::DOM->new (tap         => $tap,
                          ignorelines => qr/^## /,
                         );

See C<t/some_tap_ignore_lines.t> for an example.

=head2 Pre-process TAP

B<WARNING, experimental features!>

=over 4

=item * preprocess_ignorelines

By setting that option, C<ignorelines> is applied to the input TAP
text I<before> it is parsed.

This could help to speed up TAP parsing when there is a huge amount of
non-TAP lines that the regex engine could throw away faster than
TAP::Parser would parse it line by line.

B<There is a risk>: without that option, only lines are filtered that
are already parsed as lines by the TAP parser. If applied before
parsing, the regex could mis-match non-trivial situations.

=item * preprocess_tap

With this option, any lines that don't obviously look like TAP are
stripped away.

B<There is a substantial risk>, though: the purely line-based regex
processing could screw up when it mis-matches lines. Parsing TAP is
not as obvious as it seems first. Just think of unindented YAML or
indented YAML with strange multi-line spanning values at line starts,
or the (non-standardized and unsupported) nested indented TAP. So be
careful!

=item * noempty_tap

When a document is empty (which can also happen after preprocessing)
then this option set to 1 triggers to put in some replacement line.

 pragma +tapdom_error
 # document was empty

which in turn assigns it an error severity, so that these situations
are no longer invisible.

=item * utf8

Declare a document is UTF-8 encoded Unicode.

This triggers decoding the document accordingly, inclusive filtering
out illegal Unicode characters.

In particular it converts illegal chars into Unicode I<REPLACEMENT
CHARACTER> (C<\N{U+FFFD}> ... i.e. diamond with question mark in it).

For more info see:

=over 4

=item * https://stackoverflow.com/a/2656433/1342345

=item * https://metacpan.org/pod/Encode#FB_DEFAULT

=item * https://en.wikipedia.org/wiki/Specials_(Unicode_block)#Replacement_character

=back

Additionall convert C<\0> as it's not covered by Encode::decode() but
is still illegal for some tools.

=back

=head1 USING BITSETS

=head2 Option "usebitsets"

You can make the DOM even smaller by using the option C<usebitsets>:

 $tapdom = TAP::DOM->new (tap => $tap, usebitsets => 1 );

In this case all the 'has_*' and 'is_*' attributes are stored in a
common bitset entry 'is_has' with their respective bits set.

This reduces the memory footprint of a TAP::DOM remarkably (for large
TAP-DOMs ~40%) and is meant as an optimization option for memory
constrained problems.

=head2 Access bitset attributes via methods

You can get the actual values of 'is_*' and 'has_*' attributes
regardless of their storage as hash entries or bitsets by using the
respective methods on single entries:

 if ($tapdom->{lines}[4]->is_test) {...}
 if ($tapdom->{lines}[4]->is_ok)   {...}
 ...

or with even less direct hash access

 if ($tapdom->lines->[4]->is_test) {...}
 if ($tapdom->lines->[4]->is_ok)   {...}
 ...

=head2 Access bitset attributes via bit comparisons

You can also use constants that represent the respective bits in
expressions like this:

 if ($tapdom->{lines}[4]{is_has} | $TAP::DOM::IS_TEST) {...}

And the constants can be imported into your namespace:

 use TAP::DOM ':constants';
 if ($tapdom->{lines}[4]{is_has} | $IS_TEST ) {...}

=head1 Tweak the resulting DOM

=head2 Lowercase all key:value fieldnames

By setting option C<lowercase_fieldnames> all field names (hash keys)
in C<document_data> and C<kv_data> are set to lowercase. This is
especially helpful to normalize different casing like

 # Test-Strange-Key: Some Value
 # Test-strange-key: Some Value
 # Test-STRANGE-KEY: Some Value

etc. all into

  "strange-key" => "Some Value"

=head2 Lowercase all key:value values

By setting option C<lowercase_fieldvalues> all field values in
C<document_data> and C<kv_data> are set to lowercase. This is
especially helpful to normalize different casing like

 # Test-Strange-Key: Some Value
 # Test-Strange-Key: Some value
 # Test-Strange-Key: SOME VALUE

etc. all into

  "Strange-Key" => "some value"

B<Warning:> while the sister option C<lowercase_fieldnames> above is
obviously helpful to keep the information more together, this
C<lowercase_fieldvalues> option here should be used with care. You
loose much more information here which is usually better searched via
case-insensitive options of the mechanism you use, regular
expressions, Elasticsearch, etc.

=head2 Placing key:value pairs

Normally a key:value pair C<{foo =E<gt> bar}> from a line like

  # Test-foo: bar

ends up as entry in a has C<kv_values> under the entry before that
line - which ideally is either a normal ok/not_ok line or a plan line.

If that's not the case then it is not clear where they belong. Early
TAP::DOM versions had put them under a global entry C<document_data>.

However this makes these entries inconsistently appear in different
levels of the DOM. Therefore you can suppress that old behaviour by setting
C<disable_global_kv_data> to 1.

However, with that option now, there can be lines that appear directly
at the start with no preceding parent line, in case the plan comes at
the end of the document. To not loose those key values they can be
saved up until the plan appears later and put it there. As this
reorders data inside the DOM differently from the original document
you must explicitely request that behaviour by setting
C<put_dangling_kv_data_under_lazy_plan> to 1.

Summary: for consistency it is suggested to set both options:

 disable_global_kv_data => 1,
 put_dangling_kv_data_under_lazy_plan => 1

=head2 Normalize TAP line

When the option C<normalize> is set to true an additional field
L</normalized> is added which contains a, well, "normalized" (or
"canonicalized") variant of the C<raw> line.

Normalization rules:

=over 4

=item * line numbers, dashes, whitespace

Different variants between the (not)ok part and the actual
description, e.g. iteration number, leading dashes (like they were
"invisible" in Larry Wall's original TAP handling), and leading and
trailing whitespace are dropped:

  not ok 12 - foo
  not ok 12 foo
  not ok - foo
  not ok      foo

get normalized to

  not ok foo

=item * quote characters

Quote characters make it more difficult to transport the lines in
typical string-based APIs like in JSON payload. We completely drop
them (i.e., there is no replacement character):

A line like

  ok foo'bar"baz" drum'n'bass

becomes

  ok foobarbaz drumnbass

=item * backslashes

Backslashes are dropped, except before C<#TODO> / C<#SKIP> because
there they are used by some TAP tools to force exactly these strings
into the description, which is wrong imho but here we are...

=item * directives (TODO, SKIP)

Directives are normalized to uppercase with exactly one space left and
right to C<#>, respectively, i.e. all these lines

 not ok foo #todo my explanation
 not ok foo # todo my explanation
 not ok foo #TODO my explanation
 not ok foo # TODO my explanation
 not ok foo    #todo     my explanation

become

 not ok foo # TODO my explanation

and the same with C<SKIP>.

=back

See also the L</normalize_tap_line> utility function for how to use
this normalization outside of TAP::DOM.

=head1 ACCESSORS AND UTILITY METHODS

=head2 end_time

=head2 exit

=head2 has_problems

=head2 is_good_plan

=head2 parse_errors

=head2 parse_errors_msgs

=head2 plan

=head2 pragmas

=head2 skip_all

=head2 start_time

=head2 summary

=head2 tapdom_config

=head2 utf8_tap

The actual worker function behind C<utf8> option.

=head2 document_data

A document can contain comment lines which actually contain key/value
data, like this:

  # Test-vendor-id:  GenuineIntel
  # Test-cpu-model:  Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz
  # Test-cpu-family: 6
  # Test-flags.fpu:  1

Those lines are converted into a hash by splitting it at the C<:>
delimiter and stripping the C<# Test-> prefix. The resulting data
structure looks like this:

  # ... inside TAP::DOM ...
  document_data => {
                    'vendor-id' => 'GenuineIntel',
                    'cpu-model' => #Intel(R) Core(TM) i7-3667U CPU @ 2.00GHz',
                    'cpu-family' => 6,
                    'flags.fpu' =>  1,
                   },

=head2 tests_planned

=head2 tests_run

=head2 version

=head2 normalize_tap_line

Utility function for inside and outside TAP::DOM usage.

This function normalizes a TAP line, similar to what C<as_string()>
does but it does it slightly different and does even more.

It normalizes typical variants of formatting or numbering a TAP line
into a common form. This can make searching TAP lines easier by not
requiring regular expressions to express subtle variance. You would
search by an also normalized TAP line in the stored normalized lines.

The use of this functionality must be enabled as TAP::DOM option
C<normalize>. Applications handling normalized TAP should also use
this very function here to apply the same normalization.

This method does not depend on the TAP parser but can be used
independently on any string which is expected to be a test line
(i.e. starting with C<ok> or C<not ok>), so it can be used from other
applications, too. However, to ensure it makes sense you should ONLY
apply it to lines that B<are> guaranteed to be such I<test> lines,
which is B<not> as trivial as one might naively think. Inside TAP::DOM
with the I<normalize> option they are only applied to lines where
I<is_test> is true.

See L</Normalize TAP line> about the applied modifications.

Although the option C<normalize> itself is EXPERIMENTAL, the function
normalize_tap_line itself can still make sense outside TAP::DOM usage.

=head1 ADDITIONAL ATTRIBUTES

TAP::DOM creates attributes beyond those from TAP::Parser, usually to
simplify later processing.

=head2 severity

The C<severity> describes the combination of C<ok>/C<not ok> and
C<todo>/C<skip> directives as one single numeric value.

This allows to handle the otherwise I<nominal> values as I<ordinal>
value, i.e., it provides them with a particular order.

This order is explained as this:

=over 4

=item * 0 - represents the 'missing' severity.

It is used for all things that are not a test or as fallback when the
other attributes appear in illegal combinations (like saying both SKIP
and TODO).

=item * 1 - straight ok.

=item * 2 - ok with a C<#TODO>

That's slightly worse than a straight ok because of the directive.

=item * 3 - ok with a C<#SKIP>

That's one step worse because the ok is not from actual test
execution, as that's what skip means.

=item * 4 - not_ok with a C<#TODO>

That's worse as it represents a fail but it's a known issue.

=item * 5 - straight not_ok.

A straight fail is the worst real-world value.

=item * 6 - forbidden combination of a not_ok with a C<#SKIP>.

How can it fail when it was skipped? That's why it's even worse than
worst.

=back

A severity value is set for lines of type C<test> and C<plan>.

Additionally, it is set on the TAP::DOM-specific pragma
C<+tapdom_error> with a severity value 5 (i.e., I<not_ok>). Because a
pragma doesn't interfere with C<test>/C<plan> lines you can use this
to express an out-of-band error situation which would be lost
otherwise. Read below for more.

=head2 normalized (EXPERIMENTAL!)

The C<normalized> field contains a normalized (or "canonicalized")
variant of the C<raw> line. See L</Normalize TAP line> about the
applied modifications.

Please note, that the other fields, in particular C<description> and
C<explanation> refer to the original C<raw> line as seen by the
TAP::Parser, so they get out of sync. That's the main reason why this
feature is B<EXPERIMENTAL>.

=head1 TAP::DOM-SPECIFIC PRAGMAS

Pragmas in TAP are meant to influence the behaviour of the TAP parser.

TAP::DOM recognizes special pragmas. They are all prefixed with
C<tapdom_>.

So far there is:

=over 4

=item * +tapdom_error - assign this line a severity of 5 (I<not ok>)

You can for instance append this pragma to the TAP document during
post-processing to express an out-of-band error situation without
interfering with the existing test lines and plan.

Typical situations could be for instance errors from C<prove> or
another TAP processor, and you want to ensure this problem does not
get lost when storing the document in a database.

Pragmas allow C<kv_data> like in C<test> and C<plan> lines, so you can
transport additional error details like this:

 pragma +tapdom_error
 # Test-tapdom-error-type: prove
 # Test-tapdom-prove-exit: 1

=back

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
