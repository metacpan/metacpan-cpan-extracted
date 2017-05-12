package TestApplication::Model::DB;

use qbit;

use base qw(QBit::Application::Model::DB::Authorization);

my @ROWS = ();

sub _connect {bless {}, 'DB';}

sub _sub_with_connected_dbh {}

sub authorization {return $_[0]}

sub add {
    my ($self, $data) = @_;
    
    push(@ROWS, $data);
}

sub get {
    my ($self, $key) = @_;
    
    my %rows = map {$_->{'key'} => $_} @ROWS;
    
    return $rows{$key};
}

sub delete {
    my ($self, $key) = @_;
    
    my %rows = map {$_->{'key'} => $_} @ROWS;
    
    delete($rows{$key});
    
    @ROWS = values(%rows);
    
    return $key;
}

TRUE;