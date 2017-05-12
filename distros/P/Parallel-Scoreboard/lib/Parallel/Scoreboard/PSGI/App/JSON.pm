package Parallel::Scoreboard::PSGI::App::JSON;

use Class::Accessor::Lite;
use JSON qw(encode_json decode_json);
use Parallel::Scoreboard;

use strict;
use warnings;

Class::Accessor::Lite->mk_accessors(qw(scoreboard));

sub new {
    my $klass = shift;
    my %args = @_;
    die "mandatory parameter:scoreboard is missing"
        unless $args{scoreboard};
    # build object
    my $self = bless {
        %args,
    }, $klass;
    return $self;
}

sub to_app {
    my $self = shift;
    return sub {
        my $status = $self->scoreboard->read_all;
        for my $s (values %$status) {
            # try to decode status (or if fails, leave it as a string)
            eval {
                $s = decode_json($s);
            };
        }
        return [
            200,
            [ 'Content-Type' => 'application/json; charset=utf-8' ],
            [ encode_json($status) ],
        ];
    };
}

1;
__END__

=head1 NAME

Parallel::Scoreboard::PSGI::App::JSON - a simple PSGI app for monitoring the output of Parallel::Scoreboard in JSON format

=head1 SYNOPSIS

  use Parallel::Scoreboard;
  use Parallel::Scoreboard::PSGI::App;
  
  my $scoreboard = Parallel::Scoreboard->new(
      base_dir => '/tmp/my_scorebooard',
  );
  # return psgi app
  Parallel::Scoreboard::PSGI::App->new(
      scoreboard => $scoreboard,
  )->to_app;

=head1 SEE ALSO

L<Parallel::Scoreboard>
L<Parallel::Scoreboard::PSGI::App::JSON>
L<PSGI>

=head1 AUTHOR

Kazuho Oku E<lt>kazuhooku gmail.comE<gt>

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the same terms as Perl 5.10.

=cut
