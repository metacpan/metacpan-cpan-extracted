#!/usr/bin/env bash

# make sure that current dir is project top dir
this_script="${BASH_SOURCE[0]}"
script_directory="$( dirname "${this_script}" )"
work_dir="$( readlink -f "${script_directory}" )"
cd "$work_dir"
# make sure that current dir is project top dir

project_name=pgexplain

# Check if the session already exist, and if yes - attach, with no changes
tmux has-session -t "${project_name}" 2> /dev/null && exec tmux attach-session -t "${project_name}"

tmux new-session -d -s "${project_name}" -n "git"
tmux bind-key c new-window -c "#{pane_current_path}" -a

tmux new-window -n edit -t "${project_name}"

tmux new-window -d -n test -t "${project_name}"

tmux send-keys -t "${project_name}:git" "git status" Enter
tmux send-keys -t "${project_name}:edit" "vim -c NERDTree" Enter
tmux send-keys -t "${project_name}:test" "[[ -f ./Build ]] && ./Build distclean; perl ./Build.PL && ./Build && ./Build test" Enter

tmux attach-session -t "${project_name}"
