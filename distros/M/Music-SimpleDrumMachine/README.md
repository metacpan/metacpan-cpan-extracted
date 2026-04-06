# Music-SimpleDrumMachine
Simple 16th-note Phrase Drummer

Fire-up fluidsynth:

```shell
fluidsynth -a coreaudio -m coremidi -g 2.0 ~/Music/soundfont/FluidR3_GM.sf2
```

Then test with these commands:

```shell
perl -Ilib -MMusic::SimpleDrumMachine -E'$dm = Music::SimpleDrumMachine->new(verbose => 1, port_name => shift)' fluid
```

```shell
perl -Ilib eg/add-drums.pl fluid 90
```

```shell
perl -Ilib eg/euclidean.pl fluid 100
```