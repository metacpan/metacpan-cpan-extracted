#
#
#

INFILES=$(wildcard input/*.html)
OUTFILES=$(INFILES:input%=output%)

#-----------------------------------------------------------------------------
# Unix/ MS Windows without cygwin / MS Windows with cygwin
#
HASSHELL=yes
ifneq "$(ComSpec)" ""
  COMSPEC=$(ComSpec)
endif
ifneq "$(COMSPEC)" ""
  OS=WinXX
endif

ifeq "$(OS)" "WinXX"
  HASSHELL=$(if $(SHELL:sh.exe=),yes,no)
else
  OS=$(shell uname)
endif

ifeq "$(HASSHELL)" "no"
  PathFix=$(subst /,\,$(subst /*,\\*,$(1)))
  RM=$(COMSPEC) /C del /Q /F
  RD=$(COMSPEC) /C rd /Q
  RMDIR=$(COMSPEC) /C rd /Q /S
  MKDIR=$(COMSPEC) /C mkdir
else
  PathFix=$(1)
  RM=rm
  RD=rmdir
  RMDIR=rm -r
  MKDIR=mkdir -p
endif
#-----------------------------------------------------------------------------


all: output $(OUTFILES)

output:
	-@$(MKDIR) output

clean:
	-$(RM) $(call PathFix,$(OUTFILES))
	

output/%.html : input/%.html
	-perl -I../lib -Ilib -MTest::C2FIT -e file_runner $< $@

