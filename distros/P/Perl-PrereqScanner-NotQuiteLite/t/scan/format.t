use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # RANDERSON/HTTP-WebTest-1.02/WebTest.pm
   my ($nbytes, $max_bytes, $min_bytes, $terse, $report, $num_fail,
       $num_succeed) = @_;
   my ($report_text, $result);
   format WRITE_NBYTES =
              @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<
              $report_text,                                             $result
.
   if ($nbytes < 0) {
      warn "Invalid value of nbytes ( = $nbytes )";
      return 0;
   }
TEST

test(<<'TEST'); # CNATION/Monkeywrench-1.0/lib/HTTP/Monkeywrench.pm
            if (($click->{'sendcookie'}) && ($self->settings->{'show_cookies'})) {
                my $cookie_to_print = $self->cookie_jar->as_string;
                $~ = "COOKIES";
                write;
                format COOKIES =
      Cookie:
~~            ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
              $cookie_to_print
.
            }
            my $failed = 0;
            my $success = 0;

            $content .= '        Code: ' . $res->code . ' ' . $res->message . "\n";
            if ($res->is_redirect || $res->is_success) {
                $content .= "   Match Res:\n" if ($click->{'success_res'});
                foreach my $sr (@{ $click->{'success_res'} }) {
                    my $result;
                    if ($res->content =~ $sr) {
                        $result = "PASS" if ($self->settings->{'match_detail'});
                    } else {
                        $result = "FAIL";
                        $failed++;
                        $totalerrs++;
                    }
                    pipe (RFH,WFH);
                    format WFH =
              ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>
              $sr,                                                      $result
.
                    write WFH if ($result);
                    close WFH;
                    local $/ = undef;
                    $content .= <RFH>;
                }

                $content .= " Match Error:\n" if ($click->{'error_res'});
                foreach my $er (@{ $click->{'error_res'} }) {
                    my $result;
                    if ($res->content =~ $er) {
                        $result = "FAIL";
                        $failed++;
                        $totalerrs++;
                    } else {
                        $result = "PASS" if ($self->settings->{'match_detail'});
                    }
                    pipe (ERR_RFH,ERR_WFH);
                    format ERR_WFH =
              ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>
              $er,                                                      $result
.
                    write ERR_WFH if ($result);
                    close ERR_WFH;
                    local $/ = undef;
                    $content .= <ERR_RFH>;
                }

            } else {
                $content .= "              *** Request Failed ***\n"; #. $res->error_as_HTML;
            }
TEST

test(<<'TEST'); # MLEHMANN/Games-Sokoban-1.01/Sokoban.pm
sub new_from_file {
   my ($class, $path, $format) = @_;

   open my $fh, "<:perlio", $path
      or Carp::croak "$path: $!";
   local $/;

   $class->new (data => (scalar <$fh>), format => $format)
}

sub detect_format($) {
   my ($data) = @_;

   return "text" if $data =~ /^[ #\@\*\$\.\+\015\012\-_]+$/;

   return "rle"  if $data =~ /^[ #\@\*\$\.\+\015\012\-_|1-9]+$/;

   my ($a, $b) = unpack "ww", $data;
   return "binpack" if defined $a && defined $b;

   Carp::croak "unable to autodetect sokoban level format";
}

=item $level->data ([$new_data, [$new_data_format]])

Sets the level from the given data.

=cut

sub data {
   if (@_ > 1) {
      my ($self, $data, $format) = @_;

      $format ||= detect_format $data;

      if ($format eq "text" or $format eq "rle") {
         $data =~ y/-_|/  \n/;
         $data =~ s/(\d)(.)/$2 x $1/ge;
         my @lines = split /[\015\012]+/, $data;
         my $w = List::Util::max map length, @lines;

         $_ .= " " x ($w - length)
            for @lines;

         $self->{data} = join "\n", @lines;

      } elsif ($format eq "binpack") {
         (my ($w, $s), $data) = unpack "wwB*", $data;

         my @enc = ('#', '$', '.', '   ', ' ', '###', '*', '# ');

         $data = join "",
                 map $enc[$_],
                 unpack "C*",
                 pack "(b*)*",
                 unpack "(a3)*", $data;

         # clip extra chars (max. 2)
         my $extra = (length $data) % $w;
         substr $data, -$extra, $extra, "" if $extra;

         (substr $data, $s, 1) =~ y/ ./@+/;

         $self->{data} =
           join "\n",
           map "#$_#",
               "#" x $w,
               (unpack "(a$w)*", $data),
               "#" x $w;
           
      } else {
         Carp::croak "$format: unsupported sokoban level format requested";
      }

      $self->{format} = $format;
      $self->update;
   }

   $_[0]{data}
}
TEST

done_testing;
