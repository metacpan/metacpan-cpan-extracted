load_sample :bd_fat
load_sample :drum_cymbal_closed
load_sample :drum_snare_soft

live_loop :bd do
  use_real_time
  amp, rest = sync "/osc*/trigger/bd"
  sample :bd_fat, amp: amp
end

live_loop :hh do
  use_real_time
  amp, rest = sync "/osc*/trigger/hh"
  sample  :drum_cymbal_closed, amp: amp
end

live_loop :sn do
  use_real_time
  amp, rest = sync "/osc*/trigger/sn"
  #sample :drum_cymbal_closed, rate: rrand(1, 1.6), amp: [1.2, 0.5, 0.8, 2].choose
  sample :drum_snare_soft, amp: amp
end

live_loop :fx do
  use_real_time
  (num,) = sync "/osc*/trigger/fx"
  sample = 'mehackit_robot' + num.to_s # it works
  with_fx :reverb, room: 1 do
    with_fx :echo, phase: 0.75, mix: 1 do
      sample sample, release: 2, pan: [-1,-0.5,0,0.5,1].choose
      #sleep 4
    end
  end
end

#use_synth :tb303
#use_synth :sine

#with_fx :echo do |fx_echo|
use_synth :piano
live_loop :chords do
  use_real_time
  note, harmony =  sync "/osc*/trigger/chord"
  with_fx :echo, decay: 0.125, mix: 0.4 do
    synth :piano, note: chord(note, harmony), amp: 0.75
  end
end
#end

use_synth :bass_foundation
live_loop :bass do
  use_real_time
  note =  sync "/osc*/trigger/bass"
  synth :bass_foundation, note: note, release: 1, amp: 0.75
end


use_synth :organ_tonewheel
melody = play :C4, sustain: 60*60*2
melody.pause
#with_fx :reverb, mix: 0.1 do
with_fx :wobble,cutoff_max: 90, phase: 3, filter: 1 do
  live_loop :tb303 do
    use_real_time
    note, sustain = sync "/osc*/trigger/melody"
    #synth :organ_tonewheel, note: note, release: 0.01, decay: 0.5
    melody.control note: note, amp: 0.90
    if( sustain > 0 ) then
      melody.run
    else
      melody.pause
    end
  end
end