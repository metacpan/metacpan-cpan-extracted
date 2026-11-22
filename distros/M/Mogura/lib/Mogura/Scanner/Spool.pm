package Mogura::Scanner::Spool;
use Mojo::Base -base;
use Mojo::File qw(path);
use IO::Handle;
use Mojo::JSON qw(decode_json encode_json);
use Mogura::Protocol qw(valid_id now artifact_name);
has 'config';

sub directory {
    my ($self, $id) = @_;
    die 'Invalid scan ID' unless valid_id($id);
    return path($self->config->state, 'spool', $id);
}

sub write_record {
    my ($self, $path, $value) = @_;
    my $tmp = "$path.tmp";
    open my $fh, '>:raw', $tmp or die "Open $tmp: $!";
    print {$fh} encode_json($value) or die "Write $tmp: $!";
    $fh->flush && $fh->sync or die "Sync $tmp: $!";
    close $fh or die "Close $tmp: $!";
    rename $tmp, $path or die "Publish $path: $!";
    path($path)->dirname->open('<')->sync or die "Sync record directory: $!";
}

sub save {
    my ($self, $scan) = @_;
    my $dir = $self->directory($scan->{id})->make_path({mode => 0700});
    $scan->{sequence}++;
    $self->write_record($dir->child('scan.json'), $scan);
    return $scan;
}

sub get {
    my ($self, $id) = @_;
    my $file = $self->directory($id)->child('scan.json');
    return unless -e $file;
    return decode_json($file->slurp);
}

sub artifact {
    my ($self, $id, $kind) = @_;
    my $name = artifact_name($kind) or return;
    my $file = $self->directory($id)->child($name);
    return -f $file && !-l $file ? $file : undef;
}

sub log {
    my ($self, $id, $message) = @_;
    open my $fh, '>>:encoding(UTF-8)', $self->directory($id)->child('scan.log') or die "Log: $!";
    print {$fh} now() . " $message\n";
    close $fh or die "Log: $!";
}
1;
