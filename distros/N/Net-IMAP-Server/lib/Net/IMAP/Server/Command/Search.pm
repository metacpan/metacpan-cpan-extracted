package Net::IMAP::Server::Command::Search;

use warnings;
use strict;
use bytes;

use base qw/Net::IMAP::Server::Command/;
use DateTime::Format::Strptime;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;
    return $self->bad_command("Select a mailbox first")
        unless $self->connection->is_selected;

    return 1;
}

sub run {
    my $self = shift;

    my $filter = $self->filter($self->parsed_options);
    return unless $filter;

    my @results = map {$self->connection->sequence($_)} grep {$filter->($_)} $self->connection->get_messages('1:*');
    $self->untagged_response(join(" ", SEARCH => @results));
    $self->ok_completed;
}

my $arg_parser = DateTime::Format::Strptime->new(pattern => "%e-%b-%Y");

sub filter {
    my $self = shift;
    my @tokens = [@_]; # This ref is intentional!  It gets us the top-level AND
    my $filters = []; my @stack;
    # TODO: CHARSET support
    while (@tokens) {
        my $token = shift @tokens;
        $token = uc $token unless ref $token;
        if ($token eq "ALL") {
            push @{$filters}, sub {1};
        } elsif ($token eq "ANSWERED") {
            push @{$filters}, sub {$_[0]->has_flag('\Answered')};
        } elsif ($token eq "BCC") {
            return $self->bad_command("Parse error") unless @tokens;
            my $bcc = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->header("Bcc")||"" =~ /\Q$bcc\E/i};
        } elsif ($token eq "BEFORE") {
            return $self->bad_command("Parse error") unless @tokens;
            my $date = shift @tokens;
            my $parsed = $arg_parser->parse_datetime($date);
            return $self->bad_command("Bad date: $date") unless $parsed;
            push @{$filters}, sub {$_[0]->epoch_day_utc < $parsed->epoch };
        } elsif ($token eq "BODY") {
            return $self->bad_command("Parse error") unless @tokens;
            my $str = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->body =~ /\Q$str\E/i};  # TODO: likely needs to recurse MIME parts?
        } elsif ($token eq "CC") {
            return $self->bad_command("Parse error") unless @tokens;
            my $cc = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->header("Cc")||"" =~ /\Q$cc\E/i};
        } elsif ($token eq "DELETED") {
            push @{$filters}, sub {$_[0]->has_flag('\Deleted')};
        } elsif ($token eq "DRAFT") {
            push @{$filters}, sub {$_[0]->has_flag('\Draft')};
        } elsif ($token eq "FLAGGED") {
            push @{$filters}, sub {$_[0]->has_flag('\Flagged')};
        } elsif ($token eq "FROM") {
            return $self->bad_command("Parse error") unless @tokens;
            my $from = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->header("From")||"" =~ /\Q$from\E/i};
        } elsif ($token eq "HEADER") {
            return $self->bad_command("Parse error") unless @tokens >= 2;
            my ($header, $value) = splice(@tokens, 0, 2);
            push @{$filters}, sub {$_[0]->mime->header($header)||"" =~ /\Q$value\E/i};
        } elsif ($token eq "KEYWORD") {
            return $self->bad_command("Parse error") unless @tokens;
            my $keyword = shift @tokens;
            push @{$filters}, sub {$_[0]->has_flag($keyword)};
        } elsif ($token eq "LARGER") {
            return $self->bad_command("Parse error") unless @tokens;
            my $size = shift @tokens;
            push @{$filters}, sub {length $_[0]->mime->as_string > $size};
        } elsif ($token eq "NEW") {
            push @{$filters}, sub {$_[0]->has_flag('\Recent') and not $_->has_flag('\Seen')};
        } elsif ($token eq "NOT") {
            unshift @stack, [NOT => 1 => $filters];
            my $negation = [];
            push @{$filters}, sub {not $negation->[0]->(@_)};
            $filters = $negation;
        } elsif ($token eq "OLD") {
            push @{$filters}, sub {not $_[0]->has_flag('\Recent')};
        } elsif ($token eq "ON") {
            return $self->bad_command("Parse error") unless @tokens;
            my $date = shift @tokens;
            my $parsed = $arg_parser->parse_datetime($date);
            return $self->bad_command("Bad date: $date") unless $parsed;
            push @{$filters}, sub {$_[0]->epoch_day_utc >= $parsed->epoch and $_[0]->epoch_day_utc < $parsed->epoch + 60*60*24 };
        } elsif ($token eq "OR") {
            unshift @stack, [OR => 2 => $filters];
            my $union = [];
            push @{$filters}, sub {$union->[0]->(@_) or $union->[1]->(@_)};
            $filters = $union;
        } elsif ($token eq "RECENT") {
            push @{$filters}, sub {$_[0]->has_flag('\Recent')};
        } elsif ($token eq "SEEN") {
            push @{$filters}, sub {$_[0]->has_flag('\Seen')};
        } elsif ($token eq "SENTBEFORE") {
            return $self->bad_command("Parse error") unless @tokens;
            my $date = shift @tokens;
            my $parsed = $arg_parser->parse_datetime($date);
            return $self->bad_command("Bad date: $date") unless $parsed;
            push @{$filters}, sub {my $e = $_[0]->date_day_utc; defined $e and $e->epoch < $parsed->epoch; };
        } elsif ($token eq "SENTON") {
            return $self->bad_command("Parse error") unless @tokens;
            my $date = shift @tokens;
            my $parsed = $arg_parser->parse_datetime($date);
            return $self->bad_command("Bad date: $date") unless $parsed;
            push @{$filters}, sub {my $e = $_[0]->date_day_utc; defined $e and $e->epoch >= $parsed->epoch and $e->epoch < $parsed->epoch + 60*60*24 };
        } elsif ($token eq "SENTSINCE") {
            return $self->bad_command("Parse error") unless @tokens;
            my $date = shift @tokens;
            my $parsed = $arg_parser->parse_datetime($date);
            return $self->bad_command("Bad date: $date") unless $parsed;
            push @{$filters}, sub {my $e = $_[0]->date_day_utc; defined $e and $e->epoch >= $parsed->epoch };
        } elsif ($token eq "SINCE") {
            return $self->bad_command("Parse error") unless @tokens;
            my $date = shift @tokens;
            my $parsed = $arg_parser->parse_datetime($date);
            return $self->bad_command("Bad date: $date") unless $parsed;
            push @{$filters}, sub {$_[0]->epoch_day_utc >= $parsed->epoch }
        } elsif ($token eq "SMALLER") {
            return $self->bad_command("Parse error") unless @tokens;
            my $size = shift @tokens;
            push @{$filters}, sub {length $_[0]->mime->as_string < $size};
        } elsif ($token eq "SUBJECT") {
            return $self->bad_command("Parse error") unless @tokens;
            my $subj = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->header("Subject") =~ /\Q$subj\E/i};
        } elsif ($token eq "TEXT") {
            return $self->bad_command("Parse error") unless @tokens;
            my $str = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->as_string =~ /\Q$str\E/i};
        } elsif ($token eq "TO") {
            return $self->bad_command("Parse error") unless @tokens;
            my $to = shift @tokens;
            push @{$filters}, sub {$_[0]->mime->header("To")||"" =~ /\Q$to\E/i};
        } elsif ($token eq "UID") {
            return $self->bad_command("Parse error") unless @tokens;
            my $set = shift @tokens;
            my %uids;
            $uids{$_->uid}++ for $self->connection->selected->get_uids($set);
            push @{$filters}, sub {$uids{$_[0]->uid}};
        } elsif ($token eq "UNANSWERED") {
            push @{$filters}, sub {not $_[0]->has_flag('\Answered')};
        } elsif ($token eq "UNDELETED") {
            push @{$filters}, sub {not $_[0]->has_flag('\Deleted')};
        } elsif ($token eq "UNDRAFT") {
            push @{$filters}, sub {not $_[0]->has_flag('\Draft')};
        } elsif ($token eq "UNFLAGGED") {
            push @{$filters}, sub {not $_[0]->has_flag('\Flagged')};
        } elsif ($token eq "UNKEYWORD") {
            return $self->bad_command("Parse error") unless @tokens;
            my $keyword = shift @tokens;
            push @{$filters}, sub {not $_[0]->has_flag($keyword)};
        } elsif ($token eq "UNSEEN") {
            push @{$filters}, sub {not $_[0]->has_flag('\Seen')};
        } elsif ($token =~ $self->connection->SEQUENCE_STRING) {
            my %uids;
            $uids{$_->uid}++ for $self->connection->get_messages($token);
            push @{$filters}, sub {$uids{$_[0]->uid}};
        } elsif (ref $token) {
            unshift @stack, [AND => -1 => $filters, \@tokens];
            @tokens = @{$token};
            my $intersection = [];
            push @{$filters}, sub {
                for my $f (@{$intersection}) {
                    return unless $f->(@_);
                }
                return 1;
            };
            $filters = $intersection;
        } else {
            return $self->bad_command("Unknown search token: $token");
        }

        while (@stack and (@{$filters} == $stack[0][1] or ($stack[0][3] and not @tokens))) {
            $filters = $stack[0][2];
            @tokens = @{$stack[0][3]} if $stack[0][3];
            shift @stack;
        }
    }

    return $self->bad_command("Unclosed NOT/OR") if @stack;
    
    return shift @{$filters};
}

sub send_untagged {
    my $self = shift;

    $self->SUPER::send_untagged( expunged => 0 );
}

1;
