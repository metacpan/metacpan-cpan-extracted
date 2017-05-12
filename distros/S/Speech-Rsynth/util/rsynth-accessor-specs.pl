# spec file for create-xs-accessors.perl

@XSPEC_DEFAULTS = (
		   mname => 'UNKNOWN_FIELD',
		   mtype => 'int',
		   fname => '$mname',
		   otype => "rsynth_synth_ptr",
		   oname => "synth",
		   rtype => '$mtype',
		   rname => "RETVAL",
		   atype => '$mtype',
		   aname => 'val',
		  );

@xspex =
  (
   # output/general
   { mname=>'flags', mtype=>'int', },
   { mname=>'verbose', mtype=>'int', },
   { mname=>'help_only', mtype=>'int', },
   # audio: properties
   { mname=>'samp_rate', mtype=>'int', },
   # audio: filenames
   { mname=>'dev_filename', mtype=>'CharPtr', },
   { mname=>'linear_filename', mtype=>'CharPtr', },
   { mname=>'au_filename', mtype=>'CharPtr', },
   # audio: fds
   { mname=>'dev_fd', mtype=>'int', },
   { mname=>'linear_fd', mtype=>'int', },
   { mname=>'au_fd', mtype=>'int', },
   # synth: klatt guts
   { mname=>'mSec_per_frame', mtype=>'int', },
   { mname=>'impulse', mtype=>'int', },
   { mname=>'casc', mtype=>'int', },
   { mname=>'klatt_global.f0_flutter', fname=>'klatt_f0_flutter', mtype=>'int', },
   { mname=>'def_pars.TLTdb', fname=>'klatt_tilt_db', mtype=>'int', },
   { mname=>'def_pars.F0hz10', fname=>'klatt_f0_hz', mtype=>'int', },
   # holmes: tts guts (?)
   { mname=>'speed', mtype=>'int', },
   { mname=>'frac', mtype=>'double', },
   { mname=>'par_name', mtype=>'CharPtr', },
   { mname=>'jsru_name', mtype=>'CharPtr', },
   # dictionary
   { mname=>'rsdict.dict_path', fname=>'dict_path', mtype=>'CharPtr', },
  );

1;
