#!perl
use v5.36;
use Test::More;

do_tests();
done_testing();

#######################################################################

sub do_tests {

  my $class = 'PXF::Util';
  use_ok($class);

  # Sleep
  {
    require Time::HiRes;
    for (my $interval = 0.1; $interval < 1; $interval *= 2) {
      my $t1 = Time::HiRes::time();
      PXF::Util::minisleep($interval);
      my $t2 = Time::HiRes::time();
      my $el = $t2 - $t1;
      ok(
        ($interval*0.85 < $el < $interval*1.15 and $interval-0.1 < $el < $interval+0.1),
        "Sleep for $interval seconds is accurate within 15% and 0.1s"
      );
    }
  }

  # MD5
  {
    my %known = (
      'b' => 'kutf_uauL-w61xx3dTFXjw',
      'abcdefghijklmnopqrstuvwxyz' => 'w_zT12GS5AB9-0lsymfhOw',
    );

    my %known_incorrect = (
      'b' => 'kutf-uauL_w61xx3dTFXjw',
      'abcdefghijklmnopqrstuvwxyz' => 'w_zT12GS5AB9_0lsymfhOw',
      'random' => 'random',
    );

    foreach my $key (keys %known) {
      is(
        PXF::Util::md5_ubase64($key) => $known{$key},
        'url-encoded MD5 is correct'
      );

      for my $len (1..16) {
        is(
          PXF::Util::md5_ushort($key,$len) => substr($known{$key},0,$len),
          "url-encoded MD5 shortened to $len is correct"
        );
      }
    }

    foreach my $key (keys %known_incorrect) {
      isnt(
        PXF::Util::md5_ubase64($key) => $known_incorrect{$key},
        'Known incorrect md5 is incorrect'
      );
    }
  }

  # JSON and Base64
  {
    use utf8;
    my $bin_str = join('', map { chr($_) } 0..255);
    my $encoded = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0-P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn-AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq-wsbKztLW2t7i5uru8vb6_wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t_g4eLj5OXm5-jp6uvs7e7v8PHy8_T19vf4-fr7_P3-_w';
    is(
      PXF::Util::b64_to_u64(MIME::Base64::encode($bin_str)) => $encoded,
      'Base64 to Url-safe encoded correctly',
    );
    is(
      MIME::Base64::decode(PXF::Util::u64_to_b64($encoded)) => $bin_str,
       'Url-safe base64 decoded correctly'
    );

    my $json_data = {
      test_array1 => [1,2,3],
      test_arrayB => ['a'..'z'],
      test_hash   => { key1 => 'value1', key2 => 'value2' },
      test_utf8   => '⌨️😀🔍🌀🏁',
      ext_chars   => $bin_str,
    };
    is_deeply(
      PXF::Util::decode_ju64(PXF::Util::encode_ju64($json_data)) => $json_data,
      'JSON encode and decode'
    );

    # No illegal characters
    ok(
      (PXF::Util::encode_ju64($json_data) =~ m/^[a-zA-Z0-9_\-]+$/),
      'URL encoded contains proper characters'
    );
  }
    

  # Modules
  {
    # Use Plack::Util as a test for name to pm converstion and is-loaded test
    # We know it will be installed as Plack is required for this distribution
    require Plack::Util;
    ok(
      PXF::Util::is_module_loaded('Plack::Util'),
      'Module is loaded'
    );

    ok(
      (not PXF::Util::is_module_broken('Plack::Util')),
      'Module is not broken'
    );
    is(
      PXF::Util::name_to_pm('Plack::Util') => 'Plack/Util.pm',
      'Module name to PM checks'
    );

    eval {
      local @INC;
      push @INC, './t/tlib';
      require BrokenTest;
      1;
    };
    ok(
      (PXF::Util::is_module_broken('BrokenTest')),
      'BrokenTest module is broken'
    );
  }

}
