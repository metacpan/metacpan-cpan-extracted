package MyApp;

#use blib;
use Qt;
use Qt::QString;
use Qt::QCoreApplication;
use Qt::QTimer;
use Qt::QDataStream;
use Qt::QFile;

our @ISA = qw(Qt::QCoreApplication);

my $t;
my $this;


sub MyApp {
    my $class = 'MyApp';
    my @signals = ('signl0(double)');
    my @slots = ('slt0()', 'slt1(double)');
    $this = QCoreApplication(\@signals, \@slots, @_ );
    $t = QTimer();
    print $this, ' : ', $t, "\n";

    $this->connect( $t, SIGNAL('timeout()'), $this, SLOT('slt0()') );
    #$this->connect( $this, SIGNAL('signl0(double)'), $this, SLOT('slt1(double)') );
    CONNECT( $this, SIGNAL('signl0(double)'), $this, SLOT('slt1(double)') ); # 2nd way
    $t->start(1000);

    bless $this, $class;
    return $this;
}


sub slt0 {
    print "from slt0; 0 = $_[0]\n";
    $this->emit( 'signl0(double)', 1.1);
}


my $i = 1;
sub slt1 {
    print "from slt1\n";
    
    my $file_name = QString("in_out.txt");
    print "$file_name $$file_name{_ptr}\n";
    my $fl = QFile($file_name);
    $fl->open(2);
    my $ds = QDataStream($fl);
    print "File = $fl, DataStream = $ds\n";
    $ds << "one";
    $ds << "two";
    $fl->close();

    $fl = QFile($file_name);
    $fl->open(1);
    $ds = QDataStream($fl);
    print "File = $fl, DataStream = $ds\n";
    my $out = '';
    $ds >> $out;
    print "out1 = $out\n";
    $ds >> $out;
    print "out2 = $out\n";
    $fl->close();

    $i++;
    $this->quit() if $i > 2;
}


1;
