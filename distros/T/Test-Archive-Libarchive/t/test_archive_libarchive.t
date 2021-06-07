use Test2::V0 -no_srand => 1;
use Test::Archive::Libarchive;
use 5.020;
use experimental qw( signatures postderef );

foreach my $name (qw( ok eof warn failed fatal ))
{
  subtest "la_$name" => sub {

    my $count = 0;
    my $ret = $Test::Archive::Libarchive::code{$name};
    my @args;

    my $mock = mock 'Archive::Libarchive::Archive' => (
      add => [
        foo => sub { $count++; @args = @_; return $ret },
      ],
    );

    my $ar = Archive::Libarchive::Archive->new;

    local *la_something = \&{"la_$name"};

    la_something($ar, 'foo');
    is [$count, @args], [1, $ar], 'called correctly';

    la_something($ar, 'foo' => [1,2,3]);
    is [$count, @args], [2, $ar, 1,2,3], 'called correctly';

    is
      intercept { la_something($ar, 'bar') },
      array {
        event Fail => sub {};
        etc;
      },
      'missing method'
    ;

    $ret = 22;

    is
      intercept { la_something($ar, 'foo') },
      array {
        event Fail => sub {};
        etc;
      },
      'bad return'
    ;
    is [$count, @args], [3, $ar], 'called correctly';

    is
      intercept { la_something($ar, 'foo', [5, 6, 7]) },
      array {
        event Fail => sub {};
        etc;
      },
      'bad return'
    ;
    is [$count, @args], [4, $ar, 5, 6, 7], 'called correctly';
  };
}

subtest 'la_read_data_ok' => sub {

  is
    intercept { la_read_data_ok(undef) },
    array {
      event Fail => sub {
        call info => [
          object {
            call details => 'Object is not an instance of Archive::Libarchive::ArchiveRead';
          },
        ];
      };
      end;
    },
    'call with undef'
  ;

  is
    intercept { la_read_data_ok(Archive::Libarchive::Archive->new) },
    array {
      event Fail => sub {
        call info => [
          object {
            call details => 'Object is not an instance of Archive::Libarchive::ArchiveRead';
          },
        ];
      };
      end;
    },
    'call with non ar instance'
  ;

  my @data;

  my $mock = mock 'Archive::Libarchive::ArchiveRead' => (
    add => [
      read_data => sub ($r, $ref) {
        die "no mock data" unless defined $data[0];
        my($ret,$data) = @{ shift @data };
        $$ref = "$data";
        return $ret;
      },
    ],
  );

  @data = (
    [ 4, 'xxxx' ],
    [ 4, 'yyyy' ],
    [ 0, ''     ],
  );

  is
    la_read_data_ok(Archive::Libarchive::ArchiveRead->new),
    'xxxxyyyy',
    'content matches',
  ;

  @data = (
    [ 0, '' ],
  );

  is
    la_read_data_ok(Archive::Libarchive::ArchiveRead->new),
    '',
    'content matches',
  ;

  @data = (
    [ -25, '' ],
  );

  my $content;

  is
    intercept { $content = la_read_data_ok(Archive::Libarchive::ArchiveRead->new) },
    array {
      event Fail => sub {
        call info => [
          object {
            call details => 'Call read_data # 1 returned ARCHIVE_FAILED';
          },
        ];
      };
      end;
    },
    'read_data returns failed'
  ;

  is $content, '', 'content matches';

  @data = (
    [ 4, 'xxxx'  ],
    [ 5, 'yyyyy' ],
    [ -25, ''    ],
  );

  is
    intercept { $content = la_read_data_ok(Archive::Libarchive::ArchiveRead->new) },
    array {
      event Fail => sub {
        call info => [
          object {
            call details => 'Call read_data # 3 returned ARCHIVE_FAILED';
          },
        ];
      };
      end;
    },
    'read_data returns failed'
  ;

  is $content, 'xxxxyyyyy', 'content matches';

};

package Archive::Libarchive::Archive {
  sub new ($class) {
    bless {}, $class;
  }
}

package Archive::Libarchive::ArchiveRead {
  sub new ($class) {
    bless {}, $class;
  }
}

done_testing;
