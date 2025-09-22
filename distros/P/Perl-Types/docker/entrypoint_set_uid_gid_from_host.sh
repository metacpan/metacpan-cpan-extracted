#!/usr/bin/env bash
# align container user/group with the owner of the bind-mounted '/app' directory or "APP_DIR" env var,
# then drop privileges and exec the requested command as that user;
# works without host UID/GID env; falls back to defaults if no bind mount

set -euo pipefail

# skip user switching when not possible due to non-root user, or explicitly disabled via "SKIP_ENTRYPOINT"
if [ "$(id -u)" -ne 0 ] || [ "${SKIP_ENTRYPOINT:-0}" = "1" ]; then
  exec "$@"
fi

APP_DIR="${APP_DIR:-/app}"
USER_NAME="${USER_NAME:-perluser}"
DEFAULT_UID="${DEFAULT_UID:-1000}"
DEFAULT_GID="${DEFAULT_GID:-1000}"

# detect UID/GID of "APP_DIR" if it exists; otherwise use defaults or "FORCE_UID" & "FORCE_GID" overrides
detect_ids() {
  if [ -d "$APP_DIR" ]; then
    # Try GNU/stat first, then BSD stat as fallback.
    if stat -c %u "$APP_DIR" >/dev/null 2>&1; then
      uid="$(stat -c %u "$APP_DIR")"
      gid="$(stat -c %g "$APP_DIR")"
    else
      # BSD / macOS style (Docker Desktop mounts)
      uid="$(stat -f %u "$APP_DIR")"
      gid="$(stat -f %g "$APP_DIR")"
    fi
  else
    uid="${FORCE_UID:-$DEFAULT_UID}"
    gid="${FORCE_GID:-$DEFAULT_GID}"
  fi
}

detect_ids

# current IDs for "USER_NAME", 0 if missing
cur_uid="$(id -u "$USER_NAME" 2>/dev/null || echo 0)"
cur_gid="$(id -g "$USER_NAME" 2>/dev/null || echo 0)"

# ensure group exists with desired GID, either create or modify
if ! getent group "$USER_NAME" >/dev/null 2>&1; then
  addgroup_cmd="groupadd"
  # some minimal images use 'addgroup'; perl:*-slim has 'groupadd'
  if command -v groupadd >/dev/null 2>&1; then
    groupadd -o -g "$gid" "$USER_NAME" 2>/dev/null || true
  else
    addgroup -g "$gid" "$USER_NAME" 2>/dev/null || true
  fi
else
  if [ "$gid" != "$cur_gid" ] && command -v groupmod >/dev/null 2>&1; then
    groupmod -o -g "$gid" "$USER_NAME" 2>/dev/null || true
  fi
fi

# ensure user exists with desired UID/GID, either create or modify
if ! id "$USER_NAME" >/dev/null 2>&1; then
  if command -v useradd >/dev/null 2>&1; then
    useradd -m -u "$uid" -g "$gid" -s /bin/bash "$USER_NAME" 2>/dev/null || true
  else
    adduser -D -u "$uid" -G "$USER_NAME" "$USER_NAME" 2>/dev/null || true
  fi
else
  if [ "$uid" != "$cur_uid" ] && command -v usermod >/dev/null 2>&1; then
    usermod -o -u "$uid" -g "$gid" "$USER_NAME" 2>/dev/null || true
  fi
fi

# fix ownership of the user's home directory, so local::lib directory and caches remain writable
HOME_DIR="/home/$USER_NAME"
[ -d "$HOME_DIR" ] && chown -R "$uid:$gid" "$HOME_DIR" || true

# drop privileges and `exec`; use `gosu` if present, otherwise fallback to `su`
if command -v gosu >/dev/null 2>&1; then
  # `gosu` does a clean setuid & exec: it replaces PID 1 with your target process;
  # signals (e.g., "SIGTERM" from `docker stop`) reach your Perl application directly, with no extra wrapper process
  exec gosu "$USER_NAME" "$@"
else
  # `su` often spawns a child shell and then launches your command;
  # you can end up with an extra layer that may interfere with signal delivery and shutdown behavior;
  # signals and zombie reaping are not as robust as with `gosu`;
  # `su` may be the culprit if you see odd shutdown behavior,
  # such as process not exiting on `docker stop`, or lingering children processes
  exec su -s /bin/sh -c "$(printf '%s ' "$@")" "$USER_NAME"
fi
