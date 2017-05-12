package MySQL::Replication::Server;

use strict;
use warnings;

use base qw{ Class::Accessor };

use AnyEvent;
use Fcntl        qw{ :seek };
use Scalar::Util qw{ weaken };
use MySQL::Replication::Command;

my ( %HANDLERS, %COLLATIONS, $EXTRA_HEADER_LENGTH );

BEGIN {
  $EXTRA_HEADER_LENGTH = 0;

  use constant {
    BINLOG_READ_INTERVAL => 1,

    # binlog header
    BINLOG_MAGIC  => "\xfe\x62\x69\x6e",
    HEADER_LENGTH => 19,

    # binlog event typecodes
    QUERY_EVENT              => 2,
    INTVAR_EVENT             => 5,
    RAND_EVENT               => 13,
    USER_VAR_EVENT           => 14,
    FORMAT_DESCRIPTION_EVENT => 15,
    XID_EVENT                => 16,

    # skip event typecodes
    ROTATE_EVENT             => 4,
    TABLE_MAP_EVENT          => 19,
    PRE_GA_WRITE_ROWS_EVENT  => 20,
    PRE_GA_UPDATE_ROWS_EVENT => 21,
    PRE_GA_DELETE_ROWS_EVENT => 22,
    WRITE_ROWS_EVENT         => 23,
    UPDATE_ROWS_EVENT        => 24,
    DELETE_ROWS_EVENT        => 25,
    INCIDENT_EVENT           => 26,

    # header offsets
    OFFSET_TYPE_CODE     => 4,
    OFFSET_EVENT_LENGTH  => 9,
    OFFSET_NEXT_POSITION => 13,
    OFFSET_HEADER_LENGTH => 75,

    # query event offsets
    OFFSET_DB_LENGTH      => 8,
    OFFSET_STATUS_LENGTH  => 11,
    OFFSET_DATA_BLOCK     => 13,

    # user variable types
    STRING_RESULT  => 0,
    REAL_RESULT    => 1,
    INT_RESULT     => 2,
    ROW_RESULT     => 3,
    DECIMAL_RESULT => 4,
  };

  %HANDLERS = (
    QUERY_EVENT()    => \&QUERY,
    INTVAR_EVENT()   => \&INTVAR,
    RAND_EVENT()     => \&RAND,
    USER_VAR_EVENT() => \&USER_VAR,
    XID_EVENT()      => \&XID,
  );

  __PACKAGE__->mk_accessors( qw{
    BinlogPath
    ServerId
    StartLog
    StartPos
    EndLog
    EndPos
    CurrentLog
    CurrentPos
    NewBinlogExists
    Headers
    Query
    BinlogFh
    BinlogBuffer
    BinlogReadTimer
    CondVar
  });

  %COLLATIONS = (
    1   => { charset => "big5",     collation => "big5_chinese_ci"      },
    2   => { charset => "latin2",   collation => "latin2_czech_cs"      },
    3   => { charset => "dec8",     collation => "dec8_swedish_ci"      },
    4   => { charset => "cp850",    collation => "cp850_general_ci"     },
    5   => { charset => "latin1",   collation => "latin1_german1_ci"    },
    6   => { charset => "hp8",      collation => "hp8_english_ci"       },
    7   => { charset => "koi8r",    collation => "koi8r_general_ci"     },
    8   => { charset => "latin1",   collation => "latin1_swedish_ci"    },
    9   => { charset => "latin2",   collation => "latin2_general_ci"    },
    10  => { charset => "swe7",     collation => "swe7_swedish_ci"      },
    11  => { charset => "ascii",    collation => "ascii_general_ci"     },
    12  => { charset => "ujis",     collation => "ujis_japanese_ci"     },
    13  => { charset => "sjis",     collation => "sjis_japanese_ci"     },
    14  => { charset => "cp1251",   collation => "cp1251_bulgarian_ci"  },
    15  => { charset => "latin1",   collation => "latin1_danish_ci"     },
    16  => { charset => "hebrew",   collation => "hebrew_general_ci"    },
    18  => { charset => "tis620",   collation => "tis620_thai_ci"       },
    19  => { charset => "euckr",    collation => "euckr_korean_ci"      },
    20  => { charset => "latin7",   collation => "latin7_estonian_cs"   },
    21  => { charset => "latin2",   collation => "latin2_hungarian_ci"  },
    22  => { charset => "koi8u",    collation => "koi8u_general_ci"     },
    23  => { charset => "cp1251",   collation => "cp1251_ukrainian_ci"  },
    24  => { charset => "gb2312",   collation => "gb2312_chinese_ci"    },
    25  => { charset => "greek",    collation => "greek_general_ci"     },
    26  => { charset => "cp1250",   collation => "cp1250_general_ci"    },
    27  => { charset => "latin2",   collation => "latin2_croatian_ci"   },
    28  => { charset => "gbk",      collation => "gbk_chinese_ci"       },
    29  => { charset => "cp1257",   collation => "cp1257_lithuanian_ci" },
    30  => { charset => "latin5",   collation => "latin5_turkish_ci"    },
    31  => { charset => "latin1",   collation => "latin1_german2_ci"    },
    32  => { charset => "armscii8", collation => "armscii8_general_ci"  },
    33  => { charset => "utf8",     collation => "utf8_general_ci"      },
    34  => { charset => "cp1250",   collation => "cp1250_czech_cs"      },
    35  => { charset => "ucs2",     collation => "ucs2_general_ci"      },
    36  => { charset => "cp866",    collation => "cp866_general_ci"     },
    37  => { charset => "keybcs2",  collation => "keybcs2_general_ci"   },
    38  => { charset => "macce",    collation => "macce_general_ci"     },
    39  => { charset => "macroman", collation => "macroman_general_ci"  },
    40  => { charset => "cp852",    collation => "cp852_general_ci"     },
    41  => { charset => "latin7",   collation => "latin7_general_ci"    },
    42  => { charset => "latin7",   collation => "latin7_general_cs"    },
    43  => { charset => "macce",    collation => "macce_bin"            },
    44  => { charset => "cp1250",   collation => "cp1250_croatian_ci"   },
    47  => { charset => "latin1",   collation => "latin1_bin"           },
    48  => { charset => "latin1",   collation => "latin1_general_ci"    },
    49  => { charset => "latin1",   collation => "latin1_general_cs"    },
    50  => { charset => "cp1251",   collation => "cp1251_bin"           },
    51  => { charset => "cp1251",   collation => "cp1251_general_ci"    },
    52  => { charset => "cp1251",   collation => "cp1251_general_cs"    },
    53  => { charset => "macroman", collation => "macroman_bin"         },
    57  => { charset => "cp1256",   collation => "cp1256_general_ci"    },
    58  => { charset => "cp1257",   collation => "cp1257_bin"           },
    59  => { charset => "cp1257",   collation => "cp1257_general_ci"    },
    63  => { charset => "binary",   collation => "binary"               },
    64  => { charset => "armscii8", collation => "armscii8_bin"         },
    65  => { charset => "ascii",    collation => "ascii_bin"            },
    66  => { charset => "cp1250",   collation => "cp1250_bin"           },
    67  => { charset => "cp1256",   collation => "cp1256_bin"           },
    68  => { charset => "cp866",    collation => "cp866_bin"            },
    69  => { charset => "dec8",     collation => "dec8_bin"             },
    70  => { charset => "greek",    collation => "greek_bin"            },
    71  => { charset => "hebrew",   collation => "hebrew_bin"           },
    72  => { charset => "hp8",      collation => "hp8_bin"              },
    73  => { charset => "keybcs2",  collation => "keybcs2_bin"          },
    74  => { charset => "koi8r",    collation => "koi8r_bin"            },
    75  => { charset => "koi8u",    collation => "koi8u_bin"            },
    77  => { charset => "latin2",   collation => "latin2_bin"           },
    78  => { charset => "latin5",   collation => "latin5_bin"           },
    79  => { charset => "latin7",   collation => "latin7_bin"           },
    80  => { charset => "cp850",    collation => "cp850_bin"            },
    81  => { charset => "cp852",    collation => "cp852_bin"            },
    82  => { charset => "swe7",     collation => "swe7_bin"             },
    83  => { charset => "utf8",     collation => "utf8_bin"             },
    84  => { charset => "big5",     collation => "big5_bin"             },
    85  => { charset => "euckr",    collation => "euckr_bin"            },
    86  => { charset => "gb2312",   collation => "gb2312_bin"           },
    87  => { charset => "gbk",      collation => "gbk_bin"              },
    88  => { charset => "sjis",     collation => "sjis_bin"             },
    89  => { charset => "tis620",   collation => "tis620_bin"           },
    90  => { charset => "ucs2",     collation => "ucs2_bin"             },
    91  => { charset => "ujis",     collation => "ujis_bin"             },
    92  => { charset => "geostd8",  collation => "geostd8_general_ci"   },
    93  => { charset => "geostd8",  collation => "geostd8_bin"          },
    94  => { charset => "latin1",   collation => "latin1_spanish_ci"    },
    95  => { charset => "cp932",    collation => "cp932_japanese_ci"    },
    96  => { charset => "cp932",    collation => "cp932_bin"            },
    97  => { charset => "eucjpms",  collation => "eucjpms_japanese_ci"  },
    98  => { charset => "eucjpms",  collation => "eucjpms_bin"          },
    128 => { charset => "ucs2",     collation => "ucs2_unicode_ci"      },
    129 => { charset => "ucs2",     collation => "ucs2_icelandic_ci"    },
    130 => { charset => "ucs2",     collation => "ucs2_latvian_ci"      },
    131 => { charset => "ucs2",     collation => "ucs2_romanian_ci"     },
    132 => { charset => "ucs2",     collation => "ucs2_slovenian_ci"    },
    133 => { charset => "ucs2",     collation => "ucs2_polish_ci"       },
    134 => { charset => "ucs2",     collation => "ucs2_estonian_ci"     },
    135 => { charset => "ucs2",     collation => "ucs2_spanish_ci"      },
    136 => { charset => "ucs2",     collation => "ucs2_swedish_ci"      },
    137 => { charset => "ucs2",     collation => "ucs2_turkish_ci"      },
    138 => { charset => "ucs2",     collation => "ucs2_czech_ci"        },
    139 => { charset => "ucs2",     collation => "ucs2_danish_ci"       },
    140 => { charset => "ucs2",     collation => "ucs2_lithuanian_ci"   },
    141 => { charset => "ucs2",     collation => "ucs2_slovak_ci"       },
    142 => { charset => "ucs2",     collation => "ucs2_spanish2_ci"     },
    143 => { charset => "ucs2",     collation => "ucs2_roman_ci"        },
    144 => { charset => "ucs2",     collation => "ucs2_persian_ci"      },
    145 => { charset => "ucs2",     collation => "ucs2_esperanto_ci"    },
    146 => { charset => "ucs2",     collation => "ucs2_hungarian_ci"    },
    192 => { charset => "utf8",     collation => "utf8_unicode_ci"      },
    193 => { charset => "utf8",     collation => "utf8_icelandic_ci"    },
    194 => { charset => "utf8",     collation => "utf8_latvian_ci"      },
    195 => { charset => "utf8",     collation => "utf8_romanian_ci"     },
    196 => { charset => "utf8",     collation => "utf8_slovenian_ci"    },
    197 => { charset => "utf8",     collation => "utf8_polish_ci"       },
    198 => { charset => "utf8",     collation => "utf8_estonian_ci"     },
    199 => { charset => "utf8",     collation => "utf8_spanish_ci"      },
    200 => { charset => "utf8",     collation => "utf8_swedish_ci"      },
    201 => { charset => "utf8",     collation => "utf8_turkish_ci"      },
    202 => { charset => "utf8",     collation => "utf8_czech_ci"        },
    203 => { charset => "utf8",     collation => "utf8_danish_ci"       },
    204 => { charset => "utf8",     collation => "utf8_lithuanian_ci"   },
    205 => { charset => "utf8",     collation => "utf8_slovak_ci"       },
    206 => { charset => "utf8",     collation => "utf8_spanish2_ci"     },
    207 => { charset => "utf8",     collation => "utf8_roman_ci"        },
    208 => { charset => "utf8",     collation => "utf8_persian_ci"      },
    209 => { charset => "utf8",     collation => "utf8_esperanto_ci"    },
    210 => { charset => "utf8",     collation => "utf8_hungarian_ci"    },
  );
}

sub new {
  my ( $Class, %Args ) = @_;

  foreach my $Required ( qw{ BinlogPath StartLog StartPos } ) {
    next if $Args{$Required};
    die "Required parameter '$Required' missing";
  }

  if ( $Args{EndLog} and not $Args{EndPos} ) {
    die "EndLog specified but EndPos missing";
  }

  if ( $Args{EndPos} and not $Args{EndLog} ) {
    die "EndPos specified but EndLog missing";
  }

  my $Self = $Class->SUPER::new( \%Args );
  $Self->CurrentLog( $Self->StartLog() );
  $Self->CurrentPos( $Self->StartPos() );

  return $Self;
}

sub GetQuery {
  my ( $Self ) = @_;

  $Self->BinlogBuffer( '' );
  $Self->Headers( {} );
  $Self->Query( undef );

  weaken( my $Weak = $Self );

  $Self->BinlogReadTimer( AnyEvent->timer(
    after    => 0,
    interval => BINLOG_READ_INTERVAL,
    cb       => sub { $Weak->BinlogReadHandler() },
  )) or die "Error creating binlog read timer";

  $Self->CondVar( AnyEvent->condvar() )
    or die "Error creating condition variable";

  $Self->CondVar()->recv();
  return $Self->Query();
}

sub BinlogReadHandler {
  my ( $Self ) = @_;

  NEXT_EVENT:

  if ( not $Self->BinlogFh() ) {
    return if not $Self->_InitBinlogFh();
  }

  if ( not %{ $Self->Headers() || {} } ) {
    return if not $Self->_ReadBinlog( HEADER_LENGTH + $EXTRA_HEADER_LENGTH );
    return if $Self->_RequestComplete();

    $Self->_ParseHeaders();
  }

  return if not $Self->_ReadBinlog( $Self->Headers()->{EventLength} - HEADER_LENGTH - $EXTRA_HEADER_LENGTH );
  return if $Self->_RequestComplete();

  if ( $Self->ServerId() and ( $Self->Headers()->{ServerId} != $Self->ServerId() ) ) {
      $Self->BinlogBuffer( '' );
      $Self->Headers( {} );
      goto NEXT_EVENT;
  }

  if ( not $HANDLERS{ $Self->Headers()->{TypeCode} } ) {
    my @SkipEvents = (
      ROTATE_EVENT,
      TABLE_MAP_EVENT,
      PRE_GA_WRITE_ROWS_EVENT,
      PRE_GA_UPDATE_ROWS_EVENT,
      PRE_GA_DELETE_ROWS_EVENT,
      WRITE_ROWS_EVENT,
      UPDATE_ROWS_EVENT,
      DELETE_ROWS_EVENT,
    );

    foreach my $SkipEvent ( @SkipEvents ) {
      next unless $Self->Headers()->{TypeCode} == $SkipEvent;

      $Self->BinlogBuffer( '' );
      $Self->Headers( {} );
      goto NEXT_EVENT;
    }

    die sprintf( "Unsupported event '%s' in binlog '%s' at '%s'",
      $Self->Headers()->{TypeCode},
      $Self->_BinlogFilename(),
      $Self->CurrentPos()
    );
  }

  $HANDLERS{ $Self->Headers()->{TypeCode} }->( $Self );

  $Self->BinlogReadTimer( undef );
  $Self->CondVar()->send();
}

sub _InitBinlogFh {
  my ( $Self ) = @_;

  open my $BinlogFh, '<', $Self->_BinlogFilename()
    or die sprintf( "Error opening binlog '%s'", $Self->_BinlogFilename() );

  my $Bytes = sysread( $BinlogFh, my $Buffer, length( BINLOG_MAGIC ) + OFFSET_HEADER_LENGTH + 1 );

  if ( not defined $Bytes ) {
    die sprintf( "Error reading magic from binlog '%s' ($!)", $Self->_BinlogFilename() );
  }

  if ( $Bytes == 0 ) {
    $Self->_CheckForNewBinlog();
    return;
  }

  if ( $Bytes != length( BINLOG_MAGIC ) + OFFSET_HEADER_LENGTH + 1 ) {
    return;
  }

  my ( $Magic, $FormatDescriptionEvent, $HeaderLength ) = unpack(
    sprintf( 'a4 a%d x%d C',
      HEADER_LENGTH,
      OFFSET_HEADER_LENGTH - HEADER_LENGTH
    ),
    $Buffer,
  );

  if ( grep { not defined $_ } $Magic, $FormatDescriptionEvent, $HeaderLength ) { 
    die sprintf( "Invalid format description event in binlog '%s'", $Self->_BinlogFilename() );
  }

  if ( $Magic ne BINLOG_MAGIC ) {
    die sprintf( "Invalid magic in binlog '%s'", $Self->_BinlogFilename() );
  }

  substr $Buffer, 0, length( BINLOG_MAGIC ), '';
  $Self->BinlogBuffer( $Buffer );
  $Self->_ParseHeaders();

  if ( $Self->Headers()->{TypeCode} != FORMAT_DESCRIPTION_EVENT ) {
    die sprintf( "Format description event not found in binlog '%s'", $Self->_BinlogFilename() );
  }

  $EXTRA_HEADER_LENGTH = $HeaderLength - HEADER_LENGTH;

  if ( not $Self->CurrentPos() ) {
    $Self->CurrentPos( $Self->Headers()->{NextPosition} );
  }

  my $Tell = sysseek( $BinlogFh, $Self->CurrentPos(), SEEK_SET );

  if ( not defined $Tell ) {
    die sprintf( "Error seeking in binlog '%s' ($!)", $Self->_BinlogFilename() );
  }

  $Self->BinlogFh( $BinlogFh );
  $Self->BinlogBuffer( '' );
  $Self->Headers( {} );
  return 1;
}

sub _CheckForNewBinlog {
  my ( $Self ) = @_;

  if( $Self->NewBinlogExists() ) {
    $Self->NewBinlogExists( 0 );
    $Self->CurrentLog( $Self->CurrentLog() + 1 );
    $Self->CurrentPos( 0 );
    $Self->BinlogFh( undef );
    $Self->BinlogBuffer( '' ),
    $Self->Headers( {} );
    return;
  }

  if ( -e $Self->_BinlogFilename( 1 ) ) {
    $Self->NewBinlogExists( 1 );
    return;
  }
}

sub _ReadBinlog {
  my ( $Self, $Length ) = @_;

  my $Bytes = sysread(
    $Self->BinlogFh(),
    $Self->{BinlogBuffer},
    $Length - length( $Self->{BinlogBuffer} ),
    length( $Self->{BinlogBuffer} )
  );

  if( not defined $Bytes ) {
    die sprintf( "Error reading from binlog '%s' ($!)", $Self->_BinlogFilename() );
  }

  if ( $Bytes == 0 ) {
    $Self->_CheckForNewBinlog();
    return;
  }

  if ( length( $Self->{BinlogBuffer} ) != $Length ) {
    return;
  }

  $Self->CurrentPos( $Self->CurrentPos() + $Length );
  return 1;
}

sub _RequestComplete {
  my ( $Self ) = @_;

  return if not $Self->EndLog();
  return if $Self->CurrentLog() <  $Self->EndLog();
  return if $Self->CurrentLog() == $Self->EndLog() and $Self->CurrentPos() < $Self->EndPos();

  $Self->Query( undef );
  $Self->BinlogReadTimer( undef );
  $Self->CondVar->send();

  return 1;
}

sub _ParseHeaders {
  my ( $Self ) = @_;

  my ( $Timestamp, $TypeCode, $ServerId, $EventLength, $NextPosition ) = unpack( 'L C L L L', $Self->{BinlogBuffer} );

  if ( grep { not defined $_ } $Timestamp, $TypeCode, $ServerId, $EventLength, $NextPosition ) {
    die sprintf( "Invalid header in binlog '%s' at position %s", $Self->_BinlogFilename(), $Self->CurrentPos() );
  }

  $Self->BinlogBuffer( '' );
  $Self->Headers({
    Timestamp    => $Timestamp,
    TypeCode     => $TypeCode,
    ServerId     => $ServerId,
    EventLength  => $EventLength,
    NextPosition => $NextPosition,
  });
}

sub _BinlogFilename {
  my ( $Self, $Offset ) = @_;

  return sprintf( '%s.%06d',
    $Self->BinlogPath(),
    ( $Self->CurrentLog() + ( $Offset || 0 ) ),
  );
}

sub QUERY {
  my ( $Self ) = @_;

  my ( $DbLength, $StatusBlockLength ) = unpack(
    sprintf( 'x%d C x%d S',
      OFFSET_DB_LENGTH,
      OFFSET_STATUS_LENGTH - OFFSET_DB_LENGTH - 1
    ),
    $Self->{BinlogBuffer},
  );

  if ( grep { not defined $_ } $DbLength, $StatusBlockLength ) {
    die sprintf( "Error parsing QUERY event (static) in binlog '%' at %", $Self->_BinlogFilename(), $Self->CurrentPos() );
  }

  my ( $DbName, $Query ) = unpack(
    sprintf( 'x%d a%dx a%d',
      OFFSET_DATA_BLOCK + $StatusBlockLength,
      $DbLength,
      length( $Self->{BinlogBuffer} ) - OFFSET_DATA_BLOCK + $StatusBlockLength + $DbLength,
    ),
    $Self->{BinlogBuffer},
  );

  if ( grep { not defined $_ } $DbName, $Query ) {
    die sprintf( "Error parsing QUERY event (dynamic) in binlog '%s' at %s", $Self->_BinlogFilename(), $Self->CurrentPos() );
  }

  $Self->Query( MySQL::Replication::Command->new(
    Command => 'QUERY',
    Headers => {
      ( $DbName ? ( Database => $DbName ) : () ),
      Timestamp => $Self->Headers()->{Timestamp},
      Log       => $Self->CurrentLog(),
      Pos       => $Self->CurrentPos(),
      Length    => length( $Query ),
    },
    Body   => $Query,
  ));

  if ( not $Self->Query() ) {
    die "Error creating QUERY query ($MySQL::Replication::Command::Errstr)";
  }
}

sub INTVAR {
  my ( $Self ) = @_;

  my ( $IntType, $IntValueLow, $IntValueHigh ) = unpack( 'C L2', $Self->{BinlogBuffer} );

  if ( grep { not defined $_ } $IntType, $IntValueLow, $IntValueHigh ) {
    die sprintf( "Error parsing INTVAR event in binlog '%s' at %s", $Self->_BinlogFilename(), $Self->CurrentPos() );
  }

  use bigint;
  my $IntValue = ( $IntValueHigh << 32 ) + $IntValueLow;

  my $Query = $IntType == 1
    ? 'SET LAST_INSERT_ID=' . $IntValue
    : 'SET INSERT_ID=' . $IntValue;

  $Self->Query( MySQL::Replication::Command->new(
    Command => 'QUERY',
    Headers => {
      Timestamp => $Self->Headers()->{Timestamp},
      Log       => $Self->CurrentLog(),
      Pos       => $Self->CurrentPos(),
      Length    => length( $Query ),
    },
    Body   => $Query,
  ));

  if ( not $Self->Query() ) {
    die "Error creating INTVAR query ($MySQL::Replication::Command::Errstr)";
  }
}

sub RAND {
  my ( $Self ) = @_;

  my ( $RandSeed1Low, $RandSeed1High, $RandSeed2Low, $RandSeed2High ) = unpack( 'L4', $Self->{BinlogBuffer});

  if ( grep { not defined $_ } $RandSeed1Low, $RandSeed1High, $RandSeed1Low, $RandSeed2High  ) {
    die sprintf( "Error parsing RAND event in binlog '%s' at %s", $Self->_BinlogFilename(), $Self->CurrentPos() );
  }

  use bigint;
  my $RandSeed1 = ( $RandSeed1High << 32 ) + $RandSeed1Low;
  my $RandSeed2 = ( $RandSeed2High << 32 ) + $RandSeed2Low;

  my $Query = sprintf( 'SET @@RAND_SEED1=%s, @@RAND_SEED2=%s', $RandSeed1, $RandSeed2 );

  $Self->Query( MySQL::Replication::Command->new(
    Command => 'QUERY',
    Headers => {
      Timestamp => $Self->Headers()->{Timestamp},
      Log       => $Self->CurrentLog(),
      Pos       => $Self->CurrentPos(),
      Length    => length( $Query ),
    },
    Body   => $Query,
  ));

  if ( not $Self->Query() ) {
    die "Error creating RAND query ($MySQL::Replication::Command::Errstr)";
  }
}

sub USER_VAR {
  my ( $Self ) = @_;

  use bigint;
  my ( $Value );

  my ( $Name, $IsNull ) = unpack( 'L/a c', $Self->{BinlogBuffer} );

  if ( grep { not defined $_ } $Name, $IsNull ) {
    die sprintf( "Error parsing USER_VAR event (header) in binlog '%s' at %s", $Self->_BinlogFilename(), $Self->CurrentPos() );
  }

  if ( $IsNull ) {
    $Value = 'NULL';
  }
  else {
    my ( $Type ) = unpack( sprintf( 'x%d c', length( $Name ) + 5 ), $Self->{BinlogBuffer} );

    if ( not defined $Type ) {
      die sprintf( "Error parsing USER_VAR event (variable type) in binlog '%s' at %s",
        $Self->_BinlogFilename(), $Self->CurrentPos() );
    }

    if ( $Type == STRING_RESULT ) {
      my ( $CollationId, $Size, @Values ) = unpack( sprintf( 'x%d L L c*', length( $Name ) + 6 ), $Self->{BinlogBuffer} );

      if ( grep { not defined $_ } $CollationId, $Size, @Values ) {
        die sprintf( "Error parsing USER_VAR event (STRING_RESULT) in binlog '%s' at %s",
          $Self->_BinlogFilename(), $Self->CurrentPos() );
      }

      my $Charset   = $COLLATIONS{$CollationId} ? "_$COLLATIONS{$CollationId}{charset} "            : '';
      my $Collation = $COLLATIONS{$CollationId} ? " COLLATE `$COLLATIONS{$CollationId}{collation}`" : '';
      $Value        = $Charset . '0x' . join( '', map { uc sprintf '%x', $_ } @Values ) . $Collation;
    }
    elsif ( grep { $Type == $_ } REAL_RESULT, INT_RESULT ) {
      my ( $Low, $High ) = unpack( sprintf( 'x%d L2', length( $Name ) + 14 ), $Self->{BinlogBuffer} );

      if ( grep { not defined $_ } $Low, $High ) {
        die sprintf( "Error parsing USER_VAR event ([REAL|INT]_RESULT) in binlog '%s' at %s",
          $Self->_BinlogFilename(), $Self->CurrentPos() );
      }

      $Value = ( $High << 32 ) + $Low;
    }
    elsif ( $Type == DECIMAL_RESULT ) {
      my ( $PackedDecimal ) = unpack( sprintf( 'x%d L/a', length( $Name ) + 10 ), $Self->{BinlogBuffer} );

      if ( not defined $PackedDecimal ) {
        die sprintf( "Error parsing USER_VAR event (DECIMAL_RESULT) in binlog '%s' at %s",
          $Self->_BinlogFilename(), $Self->CurrentPos() );
      }

      my ( $Precision, $Scale, @Parts ) = unpack( 'c2 C*', $PackedDecimal );

      if ( grep { not defined $_ } $Precision, $Scale, @Parts ) {
        die sprintf( "Error parsing USER_VAR event (DECIMAL_RESULT precision) in binlog '%s' at %s",
          $Self->_BinlogFilename(), $Self->CurrentPos() );
      }

      my $Cut = 0;
      while ( length( 256 ** $Cut ) < $Precision - $Scale ) {
        $Cut++;
      }
      $Cut++;

      my @Left      = splice @Parts, 0, $Cut;
      $Left[0]     ^= 0x80;
      my $Negative  = $Left[0] & 0x80 ? 1 : 0;

      my $Left  = $Self->_UnpackDecimalPart( $Negative , 0, reverse @Left );
      my $Right = $Self->_UnpackDecimalPart( $Negative , 1, @Parts );
      $Value    = ( $Negative ? '-' : '' ) . ( $Left || 0 ) . '.' . ( $Right || 0 ); 
    }
    else {
      die sprintf( "Unknown user variable type '$Type' in binlog '%s' at %s'",
        $Self->_BinlogFilename(), $Self->CurrentPos() );
    }
  }

  my $Query = "SET @`$Name`:=$Value";

  $Self->Query( MySQL::Replication::Command->new(
    Command => 'QUERY',
    Headers => {
      Timestamp => $Self->Headers()->{Timestamp},
      Log       => $Self->CurrentLog(),
      Pos       => $Self->CurrentPos(),
      Length    => length( $Query ),
    },
    Body   => $Query,
  ));

  if ( not $Self->Query() ) {
    die "Error creating USER_VAR query ($MySQL::Replication::Command::Errstr)";
  }
}

sub XID {
  my ( $Self ) = @_;

  my $Query = 'COMMIT';

  $Self->Query( MySQL::Replication::Command->new(
    Command => 'QUERY',
    Headers => {
      Timestamp => $Self->Headers()->{Timestamp},
      Log       => $Self->CurrentLog(),
      Pos       => $Self->CurrentPos(),
      Length    => length( $Query ),
    },
    Body   => $Query,
  ));

  if ( not $Self->Query() ) {
    die "Error creating COMMIT query ($MySQL::Replication::Command::Errstr)";
  }
}

sub _UnpackDecimalPart {
  my ( $Self, $Negative, $Reverse, @Parts ) = @_;

  if ( $Negative ) {
    @Parts = map { unpack 'C', pack 'l', ~$_ } @Parts;

    if ( grep { not defined $_ } @Parts ) {
      die sprintf( "Error parsing USER_VAR event (DECIMAL_RESULT sign) in binlog '%s' at %s",
        $Self->_BinlogFilename(), $Self->CurrentPos() );
    }
  }

  my @Values;

  while ( @Parts ) {
    my @Part = splice @Parts, 0, 4;
    @Part    = reverse @Part if $Reverse;

    $Part[0] ||= 0; $Part[1] ||= 0; $Part[2] ||= 0; $Part[3] ||= 0;

    my @Unpacked = unpack 'L', pack 'C*', @Part;

    if ( grep { not defined $_ } @Unpacked ) {
      die sprintf( "Error parsing USER_VAR event (DECIMAL_RESULT parts) in binlog '%s' at %s",
        $Self->_BinlogFilename(), $Self->CurrentPos() );
    }

    unshift @Values, @Unpacked;
  }

  @Values = reverse @Values if $Reverse;

  my $Value;

  for ( my $i = 0; $i < @Values; $i++ ) {
    $Value .= ( $i == 0 or $i == @Values - 1 )
      ? $Values[$i]
      : sprintf "%09d", $Values[$i];
  }

  return $Value;
}

1;

__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Opera Software Australia Pty. Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the copyright holder nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
