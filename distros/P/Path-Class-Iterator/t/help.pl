# common testing functions

use Path::Class;

my %links = (
             'cannot_chdir' => file('test', 'link_to_cannot_chdir')->stringify,
             'foo'          => file('test', 'bar')->stringify,
             'nosuchdir'    => file('test', 'no_such_dir')->stringify
            );
my $dir = dir(qw( test cannot_chdir ));

sub setup
{
    mkdir("$dir", 0000);

    # catch fatal errs for systems that don't have symlinks
    my $no_links = 0;
    for my $real (keys %links)
    {
        unless (eval { symlink $real, $links{$real}; 1; })
        {
            $no_links = 1;
            warn "symlink returned $@ ($!)";
        }
    }

    return $no_links;
}

sub cleanup
{
    for my $r (keys %links)
    {
        my $l = $links{$r};
        unlink($l) or warn "can't unlink $l";
    }
    chmod 0777, "$dir";
    rmdir "$dir";
}

1;
