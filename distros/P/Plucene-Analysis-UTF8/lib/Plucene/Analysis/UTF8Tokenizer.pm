package Plucene::Analysis::UTF8Tokenizer;

our $VERSION = '0.02';

use base qw/Plucene::Analysis::Tokenizer/;
use strict;
use warnings;

sub token_re { //o }

sub next
{
    my $self = shift;
    my $fh = $self->{reader};

    if (!defined $self->{buffer} or length $self->{buffer} == 0) {
	$self->{buffer} .= <$fh>;
    }

    if ($self->{buffer}) {
	$self->{word} = [] unless ref $self->{word};
	$self->scantext($self->{buffer});
	$self->{buffer} = undef;
    }
}

sub scantext
{
    my $self = shift;
    my $text = shift or return;

    $text = lc $text;

    my %tok;

    foreach ($self->{word}) {
	$tok{$_} = 1;
    }

    my $c = undef;
    while ($text =~ /([a-z\d]+|\S)/go) {
	$tok{$1} = 1;
	$tok{$c . $1} = 1 if defined $c;
	$c = $1;
    }

    $self->{word} = [keys %tok];
}

1;
__END__

=head1 NAME

Plucene::Analysis::UTF8Tokenizer - Perl extension for UTF8 Tokenizer in Plucene

=head1 AUTHOR

Gea-Suan Lin, E<lt>gslin@gslin.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007, Gea-Suan Lin

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the National Chiao Tung University nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
