use strict;
use warnings;
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

done_testing;
