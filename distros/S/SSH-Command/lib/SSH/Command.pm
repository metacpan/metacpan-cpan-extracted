package SSH::Command;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use File::Temp;
use Scope::Guard;
use Net::SSH2;
use Exporter::Lite;

our $DEBUG = 0;
our $VERSION = '0.07';

our @EXPORT     = qw/ssh_execute/;

=head1 NAME

SSH::Command - interface to execute multiple commands
on host by SSH protocol without certificates ( only login + password )

=head1 SYNOPSIS

 use SSH::Command;

 my $result = ssh_execute(
    host     => '127.0.0.1',
    username => 'suxx',
    password => 'qwerty',
    commands =>
        [
            {
                cmd    => 'uname -a', # for check connection
                verify => qr/linux/i, # or  => 'linux-....' (check by 'eq')
            }
        ]
    );

 if ($result) {
    print "all ok!";
 } else {
    print "Command failed!";
 }

  Execute one command and get answer:

  my $command_answer_as_text = ssh_execute(
    host     => '127.0.0.1',
    username => 'suxx',
    password => 'qwerty',
    command  => 'uname',     # for check connection
  );


=cut

#
# Module Net::SSH2 have troubles with Perl 5.10
# use this patch http://rt.cpan.org/Public/Bug/Display.html?id=36614
# and patch Net::SSH2
#

# Convert server answer in raw ormat to string
# unpacking LIBSSH2_HOSTKEY_HASH_MD5 struct
sub raw_to_string {
    my ($raw) = @_;
    return join '', map { sprintf "%x", ord $_ } split '|', $raw;
}

# Sub for working with server over ssh / scp
sub ssh_execute {
    my %params = @_; 

    #require_once 'Net::SSH2';
    my $ssh2 = Net::SSH2->new();

    print "Start connection\n" if $DEBUG;

    unless ($params{host} && $ssh2->connect($params{host})) {
        die "SSH connection failed or host not specified!\n";
        return '';
    } else {
        print "Connection established" if $DEBUG;
    }   
    
    unless ( auth_on_ssh($ssh2, { %params }) ) {
        die "Auth failed!\n";
        return '';
    }

    # check auth result
    unless ($ssh2->auth_ok) {
        die "SSH authorization failed!\n";
        return '';
    }


    if ($params{hostkey}) { # check server fingerprint
        if (raw_to_string($ssh2->hostkey('md5')) ne lc $params{hostkey}) {
            die "Server digest verification failed!\n";
            return '';
        }
    }
    
    my $sg = Scope::Guard->new( sub { $ssh2->disconnect } );

    if ( ref $params{commands} eq 'ARRAY' ) {
        foreach my $command (@{ $params{commands} }) {

            if ( ref $command eq 'HASH' && $command->{cmd} eq 'scp_put' ) {

                unless ( put_file_to_server($command->{string}, $command->{dest_path}, $ssh2) ) {
                    return '';
                }

            } else {   
                my $result = execute_command_and_get_answer($ssh2, $command->{cmd});

                unless ( verify_answer($result, $command->{verify}) ) {
                    return '';
                }

            }
        }
    } elsif ($params{command}) {
        return execute_command_and_get_answer($ssh2, $params{command});
    }

    return 1; # all ok
}


# Try to login to server
sub auth_on_ssh {
    my ($ssh2, $params) = @_;

    # classical password auth
    if ($params->{password} && $params->{username}) {
        $ssh2->auth_password( $params->{username}, $params->{password} );
    } elsif ($params->{key_path}) {
        # auth by cert not supported
        die "Certificate auth in progress!\n";
        return '';
    } else {
        die "Not enought data for auth!\n";
        return '';
    }

    return 1;
}


# Put file to server via scp
sub put_file_to_server {
    my ($text, $dest_path, $ssh2) = @_;

    return '' unless $text && $dest_path && $ssh2;

    my $temp_file = File::Temp->new;
    $temp_file->printflush($text);
    $temp_file->seek(0, 0);
    
    #print $temp_file->getlines; -- work very unstable!
    unless ( $dest_path =~ m#^/(?:var|tmp)# ) {
        die "Danger! Upload only in /var or /tmp\n";
        return '';
    }

    unless($ssh2->scp_put($temp_file, $dest_path)) {
        die "Scp put failed!\n";
        return '';
    }

    return 1;
}


# Execute command and get answer as text
sub execute_command_and_get_answer {
    my ($ssh2, $command) = @_;

    my $chan = $ssh2->channel();
        
    $chan->exec($command);
    $chan->read(my $result, 102400);
    chomp $result; # remove \n on string tail

    return $result;
}


# Check answer
sub verify_answer {
    my ($result, $verify) = @_;

    if ( ref $verify eq 'Regexp' ) {
        if ($result !~ /$verify/) {
            die "Server answer ($result) is not match reg ex!\n";
            return '';
        }
    } elsif ($verify) {
        if ($result ne $verify) {
            die "Server answer ($result) is not equal " .
                "verify string ($verify)!\n";
            return '';
        }
    } else {
        die "Verify string is null!\n";
        return '';
    }

    return 1;
}


sub wrapper {
    # Put config data to YAML config
    my $user_dir_path   = "/var/www/vhosts/test_domain/httpdocs";
    my $config_path     = "user_dir/cfg/config.ini";
    my $sql_dump_file   = "user_dir/install/dump.sql";
    my $dist_path       = '/var/rpanel/r_0.1042_nrg.tar.bz2';
    my $config          = { }; # STUB

    ssh_execute(
        host     => 'rpanels_ssh_host',
        username => 'rpanels_ssh_username',
        password => 'rpanels_ssh_password',
        hostkey  => 'rpanels_ssh_host_digest',
        commands => [
            {
                cmd    => 'uname -a',     # for connect check
                verify => qr/linux/i,
            },

            {
                cmd    => "tar -xjf $dist_path "     .
                          "-C $user_dir_path && echo 'ok'",
                verify => 'ok'
            },

            {
                cmd       => 'scp_put',
                string    => 'some data',
                dest_path => '/tmp/some_path',
            },

            {
                cmd    => "chmod a+rwx $config_path && echo 'ok_chmod'",
                verify => 'ok_chmod',
            },

            {
                cmd    => "zcat $sql_dump_file.gz > " .
                          "$sql_dump_file && echo 'ok_zcat'",
                verify => 'ok_zcat',
            },

            {
                cmd  => "mysql -u$config->{db_user} -p$config->{db_user_password}" .
                    " -D$config->{db_name} < $sql_dump_file && echo 'ok_sql_init'",
                verify => 'ok_sql_init',
            },

            {
                cmd       => 'scp_put', 
                dest_path => "${sql_dump_file}_create_admin.sql",
                string    => "
                    SET NAMES 'cp1251';
                    INSERT INTO admin (email, passwd, first_name,last_name, support_phone, support_icq, support_email)
                    VALUES(
                        '$config->{email}',
                        MD5('$config->{passwd}'),
                        '$config->{first_name}',
                        '$config->{last_name}',
                        '$config->{support_phone}',
                        '$config->{support_icq}',
                        '$config->{support_email}'
                        );
                "
            },

            {
                cmd    => "mysql -u$config->{db_user} -p$config->{db_user_password} " .
                    "-D$config->{db_name} < ${sql_dump_file}_create_admin.sql && echo 'create_admin_ok'",
                verify => 'create_admin_ok',
            },

            {
                cmd    => "rm -rf $user_dir_path/install && echo 'ok_rm'",
                verify => 'ok_rm',
            },
        ],
    ) or return 'FAIL';
}


1;

__END__
        # Simple analogue of Scope::Guard
        my $close_handles_object = eval {
            package XXX::DestroyObject;

            sub new {
                my $class = shift;
                           
                return bless { object => shift, method => shift }, $class;
            }

            sub DESTROY {
                my $self = shift;
                
                my $object = $self->{object};
                my $method = $self->{method};

                #print "close handles!";
                return $object->$method;
            }
            __PACKAGE__
        }->new($ssh2, 'disconnect');

