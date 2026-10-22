# Optional Rex::GPU integration

## Keep GPU automation outside the generic core contract

Rex::GPU is a separate application distribution. The researched CPAN release is
0.004; main has a post-release 0.005 literal. Its detailed driver selection and
hardware compatibility belong to the installed module and current vendor guidance,
not a permanent compatibility table copied into the main skill.

`gpu_detect()` returns vendor-grouped data including NVIDIA, AMD, and NVSwitch
information. Its default detector can install `pciutils` if `lspci` is missing.
Therefore a task labeled "detect" can mutate a host. The documented experimental
Sysfs detector avoids that installation but may omit marketing names and leave
compute capability undecided. Preserve unknown values rather than coercing them
to false hardware absence. AMD detection is not AMD driver-install support.

## Setup and ownership boundaries

The module's setup coordinates driver choice, toolkit, CDI, and a selected containerd
integration target (`rke2`, `k3s`, `containerd`, or `none`). Reboot is an explicit
option, not a harmless default. Some verification failures are warnings rather than
fatal exceptions. A successful function return is therefore not complete proof of
usable CUDA workloads or Kubernetes GPU scheduling.

**Practice:** choose one owner for the driver, toolkit, CDI, and device plugin. A
preinstalled image or GPU Operator may own some of them; do not overwrite them with
an overlapping host setup. Check existing driver state before choosing an installer,
and respect incompatible GPU requirements rather than forcing one package branch.
Plan kernel/reboot recovery and preserve access to the node.

## Operational sequence

Perform authorized hardware observation, validate module/OS/hardware support, derive
a plan, approve driver/package/reboot changes, apply on a disposable or canary node,
verify the loaded driver and an actual GPU workload, then verify container runtime
and scheduler integration if required. Distinguish physical passthrough, vGPU guests,
and fabric-managed systems. Detection alone does not grant licenses or install the
appropriate licensed guest driver.

Connection prechecks in the inspected code accept Local, LibSSH, or an apparent
SFTP-capable object. They are not a substitute for testing all required filesystem
operations. The release notes' command-generation tests for CDI do not establish
real hardware success; this skill adds no hardware validation claim.

## Evidence and scope

- [lib/Rex/GPU.pm](https://github.com/Getty/rex-gpu/blob/bded1977b558c2fb6a46ae09ad2379acc5287775/lib/Rex/GPU.pm)
- [Rex::GPU (release documentation)](https://metacpan.org/pod/Rex::GPU)
- [0.004 release commit](https://github.com/Getty/rex-gpu/commit/be38cea50a75738348a2bd128dae29368e60cd4c)
