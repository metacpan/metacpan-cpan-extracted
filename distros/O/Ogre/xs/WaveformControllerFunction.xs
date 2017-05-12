MODULE = Ogre     PACKAGE = Ogre::WaveformControllerFunction

WaveformControllerFunction *
WaveformControllerFunction::new(int wType, Real base=0, Real frequency=1, Real phase=0, Real amplitude=1, bool deltaInput=true, Real dutyCycle=0.5)
  C_ARGS:
    (WaveformType)wType, base, frequency, phase, amplitude, deltaInput, dutyCycle

void
WaveformControllerFunction::DESTROY()

Real
WaveformControllerFunction::calculate(Real source)
