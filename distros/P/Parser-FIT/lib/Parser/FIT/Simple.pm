package Parser::FIT::Simple;

use strict;
use warnings;

use Parser::FIT;

sub new {
    my $class = shift;

    my $self = {};

    bless($self, $class);

    return $self;
}

sub parse {
    my $self = shift;
    my $file = shift;

    my $result = {};

    my $parser = Parser::FIT->new(on => {
        _any => sub {
            my ($msgType, $msg) = (shift, shift);
            if(!exists $result->{$msgType}) {
                $result->{$msgType} = [];
            }

            push(@{$result->{$msgType}}, $msg);
        }
    });

    $parser->parse($file);

    return $result;
}

1;

__END__
=pod

=head1 NAME
Parser::FIT::Simple - simple flat-hash parser for FIT files

=head1 SYNOPSIS

  use Parser::FIT::Simple;
  my $parser = Parser::FIT::Simple->new();
  
  my $result = $parser->parse("some/file.fit");

  print "Total Calories: " . $result->{session}->[0]->{total_calories};

=head1 DESCRIPTION

This is a simple implementation for L<Parser::FIT> which simply produces a flat hash result.

The keys of the hash correspond to the messages included in the FIT file.

The values of the hash are arrays of hashes of the actual message data.


=head1 AUTHOR

This module was created by Sven Eppler <ghandi@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2022 by Sven Eppler

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Parser::FIT>, L<https://developer.garmin.com/fit/protocol/>

=cut