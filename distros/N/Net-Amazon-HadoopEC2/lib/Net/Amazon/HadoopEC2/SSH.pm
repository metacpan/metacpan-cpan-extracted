package Net::Amazon::HadoopEC2::SSH;
use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use Path::Class::File;
use File::Spec;
use File::Basename;
use Net::SSH::Perl;
use Net::Amazon::HadoopEC2::SSH::Response;

subtype 'Net::Amazon::HadoopEC2::SSH::KeyFile'
    => as 'Path::Class::File'
    => where {
        my $st = $_[0]->stat or return;
        $st->mode == 0100600 or return;
        1;
    };

coerce 'Net::Amazon::HadoopEC2::SSH::KeyFile'
    => from 'Str'
    => via {
        return Path::Class::File->new($_[0]);
    };

has host => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has key_file => (
    is => 'ro',
    isa => 'Net::Amazon::HadoopEC2::SSH::KeyFile',
    coerce => 1,
    required => 1,
);

has retry_max => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 10,
);

has _ssh => (
    is => 'ro',
    isa => 'Net::SSH::Perl',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ssh;
        my $err = 0;
        while (1) { 
            $ssh = eval {
                Net::SSH::Perl->new(
                    $self->host,
                    identity_files => [ $self->key_file ],
                );
            };
            $err++ if $@;
            $ssh and last;
            $err > $self->retry_max and last;
            sleep 1;
        }
        $ssh or die;
        $ssh->login('root');
        return $ssh;
    },
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub push_files {
    my ($self, $args) = @_;
    for my $file ( @{$args->{files}} ) {
        -r $file or return;
        my $dest = $args->{destination};
        unless ($self->execute( { command => "test -d $args->{destination}" })->code) {
            $dest = File::Spec->catfile($args->{destination}, basename($file));
        }
        open my $fh, '<', $file or croak $!;
        my $content = do { local $/; <$fh> };
        close $fh;
        my $result = $self->execute(
            {
                command => "cat - > $dest", 
                input => $content,
            }
        );
        $result->code and return;
    }
    return 1;
}

sub get_files {
    my ($self, $args) = @_;
    for my $file ( @{$args->{files}} ) {
        my $result = $self->execute(
            {
                command => "cat $file",
            }
        );
        $result->code and return;
        my $target = $args->{destination};
        if (-d $args->{destination}) {
            $target = File::Spec->catfile($args->{destination}, basename($file));
        }
        open my $fh, '>', $target or croak $!;
        print $fh $result->stdout;
        close $fh;
    }
    return 1;
}

sub execute {
    my ($self, $args) = @_;
    my ($out, $err, $code) = $self->_ssh->cmd($args->{command}, $args->{input});
    return Net::Amazon::HadoopEC2::SSH::Response->new(
        {
            stdout => $out,
            stderr => $err,
            code   => $code,
        }
    );
}

1;
__END__

=pod

=head1 NAME

Net::Amazon::HadoopEC2::SSH - Net::SSH::Perl wrapper for Net::Amazon::HadoopEC2

=head1 DESCRIPTION

This module is Net::SSH::Perl wrapper for Net::Amazon::HadoopEC2.

=head1 METHODS

=head2 new ($hashref)

Constructor. Arguments are:

=over 4

=item host (required)

Host to connect to.

=item key_file (required)

Private key file to use with ssh connection.

=item retry_max (optional)

Maximum count of retry to connect. The default is 5.

=back

=head2 execute ($hashref)

Runs command on the master instance via ssh. 
Returns L<Net::Amazon::HadoopEC2::SSH::Response> instance. 
This is only wrapper of L<Net::SSH::Perl>.
Arguments are:

=over 4

=item command (required)

The command line to pass.

=item stdin (optional)

String to pass to STDIN of the command.

=back

=head2 push_files ($hashref)

Pushes local files to hadoop-ec2 master instance via ssh. Returns true if succeeded. 
Arguments are:

=over 4

=item files (required)

files to push. Accepts string or arrayref of strings.

=item destination (required)

Destination of the files.

=back

=head2 get_files ($hashref)

Gets files on the hadoop-ec2 master instance.  Returns true if succeeded. 
Arguments are:

=over 4

=item files (required)

files to get. String and arrayref of strings is ok.

=item destination (required)

local path to place the files.

=back

=head1 AUTHOR

Nobuo Danjou L<nobuo.danjou@gmail.com>

=head1 SEE ALSO

L<Net::Amazon::HadoopEC2>

L<Net::SSH::Perl>

=cut

