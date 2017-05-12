# Dummy notification module
# Mostly worthless

package Test::Bot::Notify::Print;

use Any::Moose;
with 'Test::Bot::Notify';

# print commit info to stdout
# big whoop
after 'notify' => sub {
    my ($self, @commits) = @_;

    foreach my $c (@commits) {
        print $c->author . " committed " . $c->id . " " . $c->display_date . ":\n" .
            '"' . $c->message . "\"\n";
        
        print "  Changed files:\n";
        foreach my $f (@{ $c->files }) {
            print "    - $f\n";
        }
        print "\n\n";
    }
};

1;
