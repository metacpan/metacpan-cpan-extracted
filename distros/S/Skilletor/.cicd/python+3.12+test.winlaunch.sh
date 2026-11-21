#!/bin/sh
# Rebuild winlaunch.exe from winlaunch/winlaunch.c and check that every
# committed hooks/*.exe and bin/*.exe is byte for byte that build. The .exe
# files are what Claude Code starts on Windows; see winlaunch/winlaunch.c.
set -eu
python3 -m venv "$CICD_OUTPUT/venv"
"$CICD_OUTPUT/venv/bin/pip" install --quiet ziglang==0.13.0.post1
"$CICD_OUTPUT/venv/bin/python" "$CICD_WORKSPACE/winlaunch/build.py" "$CICD_OUTPUT/winlaunch.exe"
sha256sum "$CICD_OUTPUT/winlaunch.exe"
status=0 found=0
for exe in "$CICD_WORKSPACE"/hooks/*.exe "$CICD_WORKSPACE"/bin/*.exe; do
	[ -e "$exe" ] || continue
	found=$((found + 1))
	if cmp -s "$exe" "$CICD_OUTPUT/winlaunch.exe"; then
		echo "ok   ${exe#"$CICD_WORKSPACE"/}"
	else
		echo "FAIL ${exe#"$CICD_WORKSPACE"/} is not a build of winlaunch/winlaunch.c"
		status=1
	fi
done
[ "$found" -gt 0 ] || { echo "FAIL no .exe under hooks/ or bin/"; status=1; }
exit $status
