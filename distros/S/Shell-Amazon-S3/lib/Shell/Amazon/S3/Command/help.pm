package Shell::Amazon::S3::Command::help;
use Moose;
use Module::Find;
use Shell::Amazon::S3::Utils;

extends 'Shell::Amazon::S3::Command';

has "+desc" => ( default => 'help', );

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( @{$tokens} != 0 ) {
        return ( 0, "error: This command doesn't need arguments" );
    }
    return ( 1, "" );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    return $tokens;
};

sub execute {
    my ( $self, $args ) = @_;
    my @commands = findsubmod Shell::Amazon::S3::Command;
    my $str = '';
    foreach my $command ( sort @commands ) {
        $str .= $self->get_command_summary($command->new) . "\n";
    }

    return $str;

}

sub get_command_summary {
    my ($self, $command) = @_;
    my $desc = $command->desc;
    sprintf("%20s -- $desc", Shell::Amazon::S3::Utils->classsuffix(ref $command));
}

# FIXME: MOVE TO help doc to each command
sub execute2 {
    my ( $self, $args ) = @_;

    my $result = '';
    $result .= "get <id>\n";
    $result .= "getacl ['bucket'|'item'] <id>\n";
    $result .= "gettorrent <id>\n";
    $result .= "head ['bucket'|'item'] <id>\n";
    $result .= "host [hostname]\n";
    $result .= "list [prefix] [max]\n";
    $result .= "listatom [prefix] [max]\n";
    $result .= "listrss [prefix] [max]\n";
    $result .= "pass [password]\n";
    $result .= "put <id> <data>\n";
# putfile <id> <file>
    $result .= "quit\n";
    $result .= "user [username]\n";

    return $result;
}

1;
