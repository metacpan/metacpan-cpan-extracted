package Plucene::SearchEngine::Index::Text;
use base 'Plucene::SearchEngine::Index::Base';

=head1 NAME

Plucene::SearchEngine::Index::Text - Backend for plain text files

=head1 DESCRIPTION

This backend sucks a plain text file into the C<text> field.

=cut

sub gather_data_from_file {
    my ($self, $file) = @_;
    my $in;
    if (exists $self->{encoding}) {
        my $encoding = $self->{encoding}{data}[0];
        open $in, "<:encoding($encoding)", $file or die $!;
    } else {
        open $in, $file or die $!;
    }
    while (<$in>) {
        $self->add_data("text" => "UnStored" => $_);
    }
    return $self;
}
1;
