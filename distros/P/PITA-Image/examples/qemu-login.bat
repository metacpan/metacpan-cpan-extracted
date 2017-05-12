REM Start qemu on windows.

REM SDL_VIDEODRIVER=directx is faster than windib. But keyboard cannot work well.
SET SDL_VIDEODRIVER=windib

REM SDL_AUDIODRIVER=waveout or dsound can be used. Only if QEMU_AUDIO_DRV=sdl.
SET SDL_AUDIODRIVER=dsound

REM QEMU_AUDIO_DRV=dsound or fmod or sdl or none can be used. See qemu -audio-help.
SET QEMU_AUDIO_DRV=dsound

REM QEMU_AUDIO_LOG_TO_MONITOR=1 displays log messages in QEMU monitor.
SET QEMU_AUDIO_LOG_TO_MONITOR=0

REM PCI-based PC(default): -M pc 
REM ISA-based PC         : -M isapc
REM -M isapc is added for NE2000 ISA card.

cd C:\\devel\\qemu
qemu.exe -L . -m 256 --snapshot -hda C:\\devel\\images\\x86-linux-debian-sarge-pita\\hda.img -cdrom C:\\devel\\images\\x86-linux-debian-sarge-pita\\minicpan3.iso -soundhw all -localtime -M pc
