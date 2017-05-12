#!perl
#
# Simple keyring usage example: check IMAP folder for newest emails.
# Non-sensitive data are taken from program args, but password is 
# got directly from the user and saved in keyring.
#
# Try running app a few times. Only on first run there should be
# password prompt.
#
# Example usage (for gmail):
#
# perl imap_query_gnome_sample.pl --machine imap.gmail.com --user joe2774 


{
    package RunMe;
    use Moose;
    with 'MooseX::Getopt';

    use Passwd::Keyring::Gnome;     # Keyring itself
    use Term::ReadKey;              # For secure password prompt
    use Net::IMAP::Simple::SSL;     # We access IMAP as illustration
    use Email::Simple;              # and get some email data.

    has 'machine' => (
        is=>'ro', isa=>'Str', required=>1,
        documentation=>'IMAP machine name, like imap.gmail.com');
    has 'port' =>  (is=>'ro', isa=>'Int', required=>1, default=> 993,
                   documentation=>'IMAP port (default 993)');
    has 'user' => (is=>'ro', isa=>'Str', required=>1,
                   documentation=>'Your username on IMAP server');
    has 'folder' => (is=>'ro', isa=>'Str', required=>1, default=>'INBOX',
                     documentation=>'The folder to check');
    has 'count' => (is=>'ro', isa=>'Int', required=>1, default=> 5,
                    documentation=>'Number of emails printed');

    my $GROUP = 'Passwd::Keyring tests and samples';
    my $APP = 'imap_query_gnome_sample';

    my $ATTEMPTS_COUNT = 3;

    sub run {
        my $self = shift;

        my $keyring = Passwd::Keyring::Gnome->new(
            app=>$APP, group=>$GROUP);

        my $imap_addr = $self->machine . ':' . $self->port;
        my $imap = Net::IMAP::Simple::SSL->new($imap_addr)
          or die "Can't connect to $imap_addr: $Net::IMAP::Simple::errstr\n";

        my $realm = "IMAP:$imap_addr";
        my $user = $self->user;
        # Attempt to recover previously saved password
        my $password = $keyring->get_password($user, $realm);
        for (my $attempt_no = 1; 1; ++ $attempt_no) {
            unless($password) {
                print "Enter password for $user on $realm: ";
                ReadMode 'noecho';
                $password = ReadLine 0; chomp($password);
                ReadMode 'normal';
                print "\n";
            }
            if( $imap->login($user, $password) ) {
                # Saving the password for future
                $keyring->set_password($user, $password, $realm);
                last; # Password OK, continuing work
            } else {
                print "IMAP login failed (bad password?). Error: " . $imap->errstr, "\n";
                # Clearing the bad password in case it was taken from keyring
                $keyring->clear_password($self->user, $realm);
                $password = '';
                # Retrying unless we exhaused attempts
                if($attempt_no >= $ATTEMPTS_COUNT) {
                    die "$attempt_no login failures, good bye\n";
                }
            }
        }

        # Actual work, as illustration

        my $folder = $self->folder;
        my $count = $imap->select($folder);
        unless(defined($count)) {
            die "Unable to open folder $folder (maybe bad name?): $Net::IMAP::Simple::errstr\n";
        }
        print "$count messages in $folder. Newest:\n";
        for(my $idx = $count;
            $idx > 0 && $idx > $count - $self->count;
            -- $idx) {
            my $email = Email::Simple->new(join '', @{ $imap->top($idx) } );
            printf("[%03d] %s\n", $idx, $email->header('Subject'));
        }
    }
}

my $run_me = RunMe->new_with_options();
$run_me->run;
