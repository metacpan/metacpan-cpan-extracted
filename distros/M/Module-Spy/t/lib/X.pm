package X;
our $Y_CNT = 0;
sub new { bless {}, shift }
sub y { $Y_CNT++; 'yyy' }
1;
