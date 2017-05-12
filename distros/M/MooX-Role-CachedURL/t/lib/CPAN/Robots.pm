package
    CPAN::Robots;

use Moo;
with 'MooX::Role::CachedURL';

has '+url' => (default => sub { 'http://www.cpan.org/robots.txt' });

sub content
{
    my $self    = shift;
    my $fh      = $self->open_file;
    my $content = '';
    local $_;

    while (<$fh>) {
        $content .= $_;
    }
    $self->close_file($fh);
    return $content;
}

1;
