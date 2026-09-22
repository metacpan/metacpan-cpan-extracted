#!/usr/bin/env perl
# demo.pl - Comprehensive async Kubernetes demo
#
# Async port of kubernetes-rest/eg/demo.pl using Net::Async::Kubernetes.
# All API calls return Futures; ->get blocks until resolved.
# The watch section uses the native async watcher with event callbacks.
#
# Prerequisites:
#   minikube start    (or any running K8s cluster with kubeconfig)
#   cpanm Net::Async::Kubernetes
#
# Usage:
#   perl -Ilib eg/demo.pl
#
# Environment:
#   KUBECONFIG  - path to kubeconfig (default: ~/.kube/config)

use strict;
use warnings;
use v5.20;
use IO::Async::Loop;
use Net::Async::Kubernetes;
use JSON::MaybeXS;
use MIME::Base64 qw(encode_base64);

my $NS = 'perl-k8s-demo';

# ============================================================
# Helper to wait for a condition (polls every 1s)
# ============================================================
sub wait_for {
    my ($desc, $check, $max) = @_;
    $max //= 30;
    say "  Waiting for $desc...";
    for my $i (1..$max) {
        my $result = eval { $check->() };
        if ($result) {
            say "  $desc: ready! (${i}s)";
            return $result;
        }
        sleep 1;
    }
    say "  $desc: timeout after ${max}s";
    return undef;
}

# ============================================================
# Connect
# ============================================================
say "=" x 60;
say "  Net::Async::Kubernetes Demo (async)";
say "=" x 60;

my $loop = IO::Async::Loop->new;

my $kube = Net::Async::Kubernetes->new(
    kubeconfig => $ENV{KUBECONFIG} // "$ENV{HOME}/.kube/config",
);
$loop->add($kube);

my $rest = $kube->rest;

# ============================================================
# Helper: create or fetch existing resource
# ============================================================
sub create_or_get {
    my ($kind, $name, $object, %get_args) = @_;
    my $created = eval { $kube->create($object)->get };
    return $created if $created;
    my $err = $@;
    if ($err =~ /AlreadyExists|already exists/i) {
        say "  (already exists, fetching)";
        return $kube->get($kind, $name, %get_args)->get;
    }
    die $err;
}

my $version = eval { $rest->cluster_version } // 'unknown';
say "\nCluster version: $version";

# ============================================================
# 1. Explore the cluster
# ============================================================
say "\n" . "=" x 60;
say "  1. CLUSTER EXPLORATION";
say "=" x 60;

say "\n--- Nodes ---";
my $nodes = $kube->list('Node')->get;
for my $node ($nodes->items->@*) {
    my $info = $node->status->nodeInfo;
    printf "  %-20s OS=%-8s kubelet=%-12s arch=%s\n",
        $node->metadata->name,
        $info->operatingSystem // '?',
        $info->kubeletVersion // '?',
        $info->architecture // '?';
}

say "\n--- Namespaces ---";
my $ns_list = $kube->list('Namespace')->get;
for my $ns ($ns_list->items->@*) {
    printf "  %-25s %s\n", $ns->metadata->name, $ns->status->phase // '';
}

say "\n--- Services in kube-system ---";
my $sys_svc = $kube->list('Service', namespace => 'kube-system')->get;
for my $svc ($sys_svc->items->@*) {
    my $ports = join ', ', map {
        ($_->port // '?') . '/' . ($_->protocol // 'TCP')
    } ($svc->spec->ports // [])->@*;
    printf "  %-30s %-12s %s\n",
        $svc->metadata->name,
        $svc->spec->type // 'ClusterIP',
        $ports;
}

# ============================================================
# 2. Create namespace
# ============================================================
say "\n" . "=" x 60;
say "  2. NAMESPACE SETUP";
say "=" x 60;

say "\n--- Creating namespace '$NS' ---";
# If the namespace is Terminating from a previous run, wait for it
my $existing_ns = eval { $kube->get('Namespace', $NS)->get };
if ($existing_ns && ($existing_ns->status->phase // '') eq 'Terminating') {
    say "  Namespace is Terminating, waiting for deletion...";
    for (1..120) {
        last unless eval { $kube->get('Namespace', $NS)->get };
        sleep 1;
    }
}

my $ns_obj = create_or_get('Namespace', $NS,
    $rest->new_object(Namespace =>
        metadata => {
            name   => $NS,
            labels => { project => 'perl-k8s-demo', managed_by => 'perl' },
        },
    ),
);
say "  Created: " . $ns_obj->metadata->name . " (uid: " . $ns_obj->metadata->uid . ")";

# ============================================================
# 3. LimitRange - default resource limits
# ============================================================
say "\n" . "=" x 60;
say "  3. LIMIT RANGE";
say "=" x 60;

say "\n--- Creating LimitRange ---";
my $lr = create_or_get('LimitRange', 'default-limits',
    $rest->new_object(LimitRange =>
        metadata => {
            name      => 'default-limits',
            namespace => $NS,
        },
        spec => {
            limits => [{
                type => 'Container',
                default => {
                    cpu    => '200m',
                    memory => '128Mi',
                },
                defaultRequest => {
                    cpu    => '50m',
                    memory => '64Mi',
                },
            }],
        },
    ),
    namespace => $NS,
);
say "  LimitRange: " . $lr->metadata->name;
say "  Default CPU: 200m, Memory: 128Mi";

# ============================================================
# 4. ResourceQuota
# ============================================================
say "\n" . "=" x 60;
say "  4. RESOURCE QUOTA";
say "=" x 60;

say "\n--- Creating ResourceQuota ---";
my $quota = create_or_get('ResourceQuota', 'namespace-quota',
    $rest->new_object(ResourceQuota =>
        metadata => {
            name      => 'namespace-quota',
            namespace => $NS,
        },
        spec => {
            hard => {
                pods                    => '20',
                'requests.cpu'          => '2',
                'requests.memory'       => '1Gi',
                'limits.cpu'            => '4',
                'limits.memory'         => '2Gi',
                persistentvolumeclaims  => '5',
                services                => '10',
                secrets                 => '10',
                configmaps              => '10',
            },
        },
    ),
    namespace => $NS,
);
say "  ResourceQuota: " . $quota->metadata->name;
my $hard = $quota->spec->hard;
say "  Limits: pods=$hard->{pods}, cpu=$hard->{'limits.cpu'}, memory=$hard->{'limits.memory'}";

# ============================================================
# 5. ConfigMap
# ============================================================
say "\n" . "=" x 60;
say "  5. CONFIGMAP";
say "=" x 60;

say "\n--- Creating ConfigMap ---";
my $cm = create_or_get('ConfigMap', 'app-config',
    $rest->new_object(ConfigMap =>
        metadata => {
            name      => 'app-config',
            namespace => $NS,
            labels    => { app => 'demo-app' },
        },
        data => {
            'app.env'       => 'staging',
            'app.debug'     => 'true',
            'app.log_level' => 'info',
            'nginx.conf'    => join("\n",
                'server {',
                '    listen 80;',
                '    server_name localhost;',
                '    location / {',
                '        root /usr/share/nginx/html;',
                '        index index.html;',
                '    }',
                '    location /health {',
                '        return 200 "ok\n";',
                '    }',
                '}',
            ),
        },
    ),
    namespace => $NS,
);
say "  ConfigMap: " . $cm->metadata->name;
say "  Keys: " . join(', ', sort keys %{$cm->data});

# ============================================================
# 6. Secret
# ============================================================
say "\n" . "=" x 60;
say "  6. SECRET";
say "=" x 60;

say "\n--- Creating Secret (Opaque) ---";
my $secret = create_or_get('Secret', 'db-credentials',
    $rest->new_object(Secret =>
        metadata => {
            name      => 'db-credentials',
            namespace => $NS,
            labels    => { app => 'demo-app' },
        },
        type => 'Opaque',
        data => {
            username => encode_base64('demo_user', ''),
            password => encode_base64('s3cret!p4ss', ''),
            host     => encode_base64('postgres.example.com', ''),
        },
    ),
    namespace => $NS,
);
say "  Secret: " . $secret->metadata->name . " (type: " . $secret->type . ")";
say "  Keys: " . join(', ', sort keys %{$secret->data});

# ============================================================
# 7. ServiceAccount + RBAC
# ============================================================
say "\n" . "=" x 60;
say "  7. SERVICEACCOUNT + RBAC";
say "=" x 60;

say "\n--- Creating ServiceAccount ---";
my $sa = create_or_get('ServiceAccount', 'demo-sa',
    $rest->new_object(ServiceAccount =>
        metadata => {
            name      => 'demo-sa',
            namespace => $NS,
            labels    => { app => 'demo-app' },
        },
    ),
    namespace => $NS,
);
say "  ServiceAccount: " . $sa->metadata->name;

say "\n--- Creating Role ---";
my $role = create_or_get('Role', 'demo-role',
    $rest->new_object(Role =>
        metadata => {
            name      => 'demo-role',
            namespace => $NS,
        },
        rules => [{
            apiGroups => [''],
            resources => ['pods', 'services', 'configmaps'],
            verbs     => ['get', 'list', 'watch'],
        }, {
            apiGroups => ['apps'],
            resources => ['deployments'],
            verbs     => ['get', 'list'],
        }],
    ),
    namespace => $NS,
);
say "  Role: " . $role->metadata->name;
say "  Rules: " . scalar($role->rules->@*) . " rules defined";

say "\n--- Creating RoleBinding ---";
my $rb = create_or_get('RoleBinding', 'demo-role-binding',
    $rest->new_object(RoleBinding =>
        metadata => {
            name      => 'demo-role-binding',
            namespace => $NS,
        },
        roleRef => {
            apiGroup => 'rbac.authorization.k8s.io',
            kind     => 'Role',
            name     => 'demo-role',
        },
        subjects => [{
            kind      => 'ServiceAccount',
            name      => 'demo-sa',
            namespace => $NS,
        }],
    ),
    namespace => $NS,
);
say "  RoleBinding: " . $rb->metadata->name;

# ============================================================
# 8. PersistentVolumeClaim
# ============================================================
say "\n" . "=" x 60;
say "  8. PERSISTENT VOLUME CLAIM";
say "=" x 60;

say "\n--- Creating PVC ---";
my $pvc = create_or_get('PersistentVolumeClaim', 'demo-storage',
    $rest->new_object(PersistentVolumeClaim =>
        metadata => {
            name      => 'demo-storage',
            namespace => $NS,
            labels    => { app => 'demo-app' },
        },
        spec => {
            accessModes => ['ReadWriteOnce'],
            resources => {
                requests => { storage => '100Mi' },
            },
        },
    ),
    namespace => $NS,
);
say "  PVC: " . $pvc->metadata->name;
say "  Access: ReadWriteOnce, Size: 100Mi";

# ============================================================
# 9. Deployment
# ============================================================
say "\n" . "=" x 60;
say "  9. DEPLOYMENT";
say "=" x 60;

say "\n--- Creating Deployment (nginx, 2 replicas) ---";
my $deploy = create_or_get('Deployment', 'demo-nginx',
    $rest->new_object(Deployment =>
        metadata => {
            name      => 'demo-nginx',
            namespace => $NS,
            labels    => { app => 'demo-app', component => 'web' },
        },
        spec => {
            replicas => 2,
            selector => {
                matchLabels => { app => 'demo-app', component => 'web' },
            },
            template => {
                metadata => {
                    labels => {
                        app       => 'demo-app',
                        component => 'web',
                    },
                    annotations => {
                        'perl-managed' => 'true',
                    },
                },
                spec => {
                    serviceAccountName => 'demo-sa',
                    containers => [{
                        name  => 'nginx',
                        image => 'nginx:1.27-alpine',
                        ports => [{ containerPort => 80 }],
                        env => [{
                            name => 'APP_ENV',
                            valueFrom => {
                                configMapKeyRef => {
                                    name => 'app-config',
                                    key  => 'app.env',
                                },
                            },
                        }, {
                            name => 'DB_USER',
                            valueFrom => {
                                secretKeyRef => {
                                    name => 'db-credentials',
                                    key  => 'username',
                                },
                            },
                        }],
                        volumeMounts => [{
                            name      => 'config-volume',
                            mountPath => '/etc/nginx/conf.d',
                        }, {
                            name      => 'data-volume',
                            mountPath => '/data',
                        }],
                        resources => {
                            requests => { cpu => '50m',  memory => '32Mi' },
                            limits   => { cpu => '100m', memory => '64Mi' },
                        },
                        livenessProbe => {
                            httpGet => { path => '/', port => 80 },
                            initialDelaySeconds => 5,
                            periodSeconds => 10,
                        },
                        readinessProbe => {
                            httpGet => { path => '/', port => 80 },
                            initialDelaySeconds => 3,
                            periodSeconds => 5,
                        },
                    }],
                    volumes => [{
                        name => 'config-volume',
                        configMap => {
                            name => 'app-config',
                            items => [{
                                key  => 'nginx.conf',
                                path => 'default.conf',
                            }],
                        },
                    }, {
                        name => 'data-volume',
                        persistentVolumeClaim => {
                            claimName => 'demo-storage',
                        },
                    }],
                },
            },
        },
    ),
    namespace => $NS,
);
say "  Deployment: " . $deploy->metadata->name;
say "  Replicas: " . $deploy->spec->replicas;
say "  Image: nginx:1.27-alpine";

# Wait for pods to start
wait_for("deployment pods to be ready", sub {
    my $pods = $kube->list('Pod', namespace => $NS)->get;
    my @running = grep {
        ($_->status->phase // '') eq 'Running'
    } $pods->items->@*;
    return @running >= 2 ? 1 : 0;
}, 60);

# ============================================================
# 10. Service (NodePort)
# ============================================================
say "\n" . "=" x 60;
say "  10. SERVICE";
say "=" x 60;

say "\n--- Creating Service (NodePort) ---";
my $svc = create_or_get('Service', 'demo-nginx',
    $rest->new_object(Service =>
        metadata => {
            name      => 'demo-nginx',
            namespace => $NS,
            labels    => { app => 'demo-app' },
        },
        spec => {
            type     => 'NodePort',
            selector => { app => 'demo-app', component => 'web' },
            ports => [{
                name       => 'http',
                port       => 80,
                targetPort => 80,
                protocol   => 'TCP',
            }],
        },
    ),
    namespace => $NS,
);
say "  Service: " . $svc->metadata->name;
say "  Type: " . $svc->spec->type;
my $node_port = $svc->spec->ports->[0]->nodePort // 'pending';
say "  NodePort: $node_port";
say "  Access via: minikube service demo-nginx -n $NS";

# ============================================================
# 11. List all pods with details
# ============================================================
say "\n" . "=" x 60;
say "  11. POD INSPECTION";
say "=" x 60;

say "\n--- Pods in $NS ---";
my $pods = $kube->list('Pod', namespace => $NS)->get;
for my $pod ($pods->items->@*) {
    my $name    = $pod->metadata->name;
    my $phase   = $pod->status->phase // 'Unknown';
    my $ip      = $pod->status->podIP // 'pending';
    my $node    = $pod->spec->nodeName // 'unscheduled';
    my $restarts = 0;
    if ($pod->status->containerStatuses) {
        $restarts = $pod->status->containerStatuses->[0]->restartCount // 0;
    }
    printf "  %-45s %-10s IP=%-16s Node=%-15s Restarts=%d\n",
        $name, $phase, $ip, $node, $restarts;
}

# ============================================================
# 12. Scale the Deployment
# ============================================================
say "\n" . "=" x 60;
say "  12. SCALING";
say "=" x 60;

say "\n--- Scaling deployment to 3 replicas ---";
my $scaled;
for my $attempt (1..5) {
    my $dep = $kube->get('Deployment', 'demo-nginx', namespace => $NS)->get;
    say "  Current replicas: " . $dep->spec->replicas if $attempt == 1;
    $dep->spec->replicas(3);
    $scaled = eval { $kube->update($dep)->get };
    last if $scaled;
    say "  Attempt $attempt conflict, retrying...";
    sleep 1;
}
die "Failed to scale deployment after 5 attempts\n" unless $scaled;
say "  Updated replicas: " . $scaled->spec->replicas;

wait_for("3rd pod to start", sub {
    my $pods = $kube->list('Pod', namespace => $NS)->get;
    my @running = grep {
        ($_->status->phase // '') eq 'Running'
        && ($_->metadata->name // '') =~ /demo-nginx/
    } $pods->items->@*;
    return @running >= 3 ? 1 : 0;
}, 60);

say "\n--- Pods after scaling ---";
$pods = $kube->list('Pod', namespace => $NS)->get;
my $nginx_count = 0;
for my $pod ($pods->items->@*) {
    next unless ($pod->metadata->name // '') =~ /demo-nginx/;
    $nginx_count++;
    printf "  %-45s %s\n", $pod->metadata->name, $pod->status->phase // '?';
}
say "  Total nginx pods: $nginx_count";

# ============================================================
# 13. Patch (partial update)
# ============================================================
say "\n" . "=" x 60;
say "  13. PATCH (partial update)";
say "=" x 60;

say "\n--- Adding label via strategic merge patch ---";
my $patched = $kube->patch('Deployment', 'demo-nginx',
    namespace => $NS,
    patch     => {
        metadata => { labels => { patched_by => 'perl', version => '2' } },
    },
)->get;
my $labels = $patched->metadata->labels // {};
say "  Labels after patch:";
for my $key (sort keys %$labels) {
    say "    $key = $labels->{$key}";
}

say "\n--- Adding annotation via merge patch ---";
$patched = $kube->patch('Deployment', 'demo-nginx',
    namespace => $NS,
    type      => 'merge',
    patch     => {
        metadata => {
            annotations => { 'demo.perl/patched' => 'true' },
        },
    },
)->get;
say "  annotation demo.perl/patched = " . ($patched->metadata->annotations->{'demo.perl/patched'} // '?');

# ============================================================
# 14. Rolling Update
# ============================================================
say "\n" . "=" x 60;
say "  14. ROLLING UPDATE";
say "=" x 60;

say "\n--- Updating image to nginx:1.27-bookworm ---";
my $rolled;
for my $attempt (1..5) {
    my $dep = $kube->get('Deployment', 'demo-nginx', namespace => $NS)->get;
    my $old_image = $dep->spec->template->spec->containers->[0]->image;
    say "  Old image: $old_image" if $attempt == 1;

    # Update the container image
    $dep->spec->template->spec->containers->[0]->image('nginx:1.27-bookworm');
    # Add annotation to track the change
    my $tpl_annotations = $dep->spec->template->metadata->annotations // {};
    $tpl_annotations->{'kubernetes.io/change-cause'} = 'Updated nginx to bookworm variant via Perl';
    $dep->spec->template->metadata->annotations($tpl_annotations);

    $rolled = eval { $kube->update($dep)->get };
    last if $rolled;
    say "  Attempt $attempt conflict, retrying...";
    sleep 1;
}
die "Failed to update deployment after 5 attempts\n" unless $rolled;
say "  New image: " . $rolled->spec->template->spec->containers->[0]->image;

wait_for("rolling update to complete", sub {
    my $d = $kube->get('Deployment', 'demo-nginx', namespace => $NS)->get;
    my $updated = $d->status->updatedReplicas // 0;
    my $ready   = $d->status->readyReplicas // 0;
    my $desired = $d->spec->replicas // 3;
    return ($updated == $desired && $ready == $desired) ? 1 : 0;
}, 90);

# ============================================================
# 15. Job
# ============================================================
say "\n" . "=" x 60;
say "  15. JOB (run to completion)";
say "=" x 60;

say "\n--- Creating Job ---";
my $job = create_or_get('Job', 'demo-job',
    $rest->new_object(Job =>
        metadata => {
            name      => 'demo-job',
            namespace => $NS,
            labels    => { app => 'demo-app', type => 'batch' },
        },
        spec => {
            backoffLimit            => 2,
            ttlSecondsAfterFinished => 300,
            template => {
                spec => {
                    restartPolicy => 'Never',
                    containers => [{
                        name    => 'worker',
                        image   => 'busybox:latest',
                        command => ['sh', '-c',
                            'echo "Job started at $(date)"; '
                            . 'echo "Processing items..."; '
                            . 'for i in 1 2 3 4 5; do echo "  Item $i done"; sleep 1; done; '
                            . 'echo "Job completed at $(date)"'
                        ],
                        resources => {
                            requests => { cpu => '25m', memory => '16Mi' },
                            limits   => { cpu => '50m', memory => '32Mi' },
                        },
                    }],
                },
            },
        },
    ),
    namespace => $NS,
);
say "  Job: " . $job->metadata->name;

wait_for("job to complete", sub {
    my $j = $kube->get('Job', 'demo-job', namespace => $NS)->get;
    return ($j->status->succeeded // 0) >= 1 ? 1 : 0;
}, 60);

my $j = $kube->get('Job', 'demo-job', namespace => $NS)->get;
say "  Succeeded: " . ($j->status->succeeded // 0);
say "  Completion: " . ($j->status->completionTime // 'pending');

# ============================================================
# 16. CronJob
# ============================================================
say "\n" . "=" x 60;
say "  16. CRONJOB";
say "=" x 60;

say "\n--- Creating CronJob (every minute) ---";
my $cron = create_or_get('CronJob', 'demo-cronjob',
    $rest->new_object(CronJob =>
        metadata => {
            name      => 'demo-cronjob',
            namespace => $NS,
            labels    => { app => 'demo-app', type => 'scheduled' },
        },
        spec => {
            schedule                   => '*/1 * * * *',
            successfulJobsHistoryLimit => 2,
            failedJobsHistoryLimit     => 1,
            jobTemplate => {
                spec => {
                    template => {
                        spec => {
                            restartPolicy => 'OnFailure',
                            containers => [{
                                name    => 'cron-worker',
                                image   => 'busybox:latest',
                                command => ['sh', '-c', 'echo "Cron tick at $(date)"'],
                                resources => {
                                    requests => { cpu => '10m', memory => '8Mi' },
                                    limits   => { cpu => '25m', memory => '16Mi' },
                                },
                            }],
                        },
                    },
                },
            },
        },
    ),
    namespace => $NS,
);
say "  CronJob: " . $cron->metadata->name;
say "  Schedule: " . $cron->spec->schedule;

# ============================================================
# 17. Utility pod
# ============================================================
say "\n" . "=" x 60;
say "  17. UTILITY POD";
say "=" x 60;

say "\n--- Creating utility pod with all config ---";
my $util_pod = create_or_get('Pod', 'demo-utility',
    $rest->new_object(Pod =>
        metadata => {
            name      => 'demo-utility',
            namespace => $NS,
            labels    => { app => 'demo-app', component => 'utility' },
            annotations => {
                'purpose' => 'Demonstrates ConfigMap + Secret access from a pod',
            },
        },
        spec => {
            serviceAccountName => 'demo-sa',
            restartPolicy => 'Never',
            containers => [{
                name    => 'util',
                image   => 'busybox:latest',
                command => ['sh', '-c', join('; ',
                    'echo "=== Environment ==="',
                    'echo "APP_ENV=$APP_ENV"',
                    'echo "LOG_LEVEL=$LOG_LEVEL"',
                    'echo "DB_HOST=$DB_HOST"',
                    'echo ""',
                    'echo "=== Config Files ==="',
                    'echo "nginx.conf:"',
                    'cat /config/nginx.conf',
                    'echo ""',
                    'echo "=== Persistent Storage ==="',
                    'echo "Hello from Perl" > /data/test.txt',
                    'cat /data/test.txt',
                    'echo ""',
                    'echo "=== Service Account ==="',
                    'ls /var/run/secrets/kubernetes.io/serviceaccount/',
                    'sleep 120',
                )],
                env => [{
                    name => 'APP_ENV',
                    valueFrom => {
                        configMapKeyRef => { name => 'app-config', key => 'app.env' },
                    },
                }, {
                    name => 'LOG_LEVEL',
                    valueFrom => {
                        configMapKeyRef => { name => 'app-config', key => 'app.log_level' },
                    },
                }, {
                    name => 'DB_HOST',
                    valueFrom => {
                        secretKeyRef => { name => 'db-credentials', key => 'host' },
                    },
                }],
                volumeMounts => [{
                    name      => 'config',
                    mountPath => '/config',
                }, {
                    name      => 'data',
                    mountPath => '/data',
                }],
                resources => {
                    requests => { cpu => '10m', memory => '8Mi' },
                    limits   => { cpu => '25m', memory => '16Mi' },
                },
            }],
            volumes => [{
                name => 'config',
                configMap => { name => 'app-config' },
            }, {
                name => 'data',
                persistentVolumeClaim => { claimName => 'demo-storage' },
            }],
        },
    ),
    namespace => $NS,
);
say "  Utility Pod: " . $util_pod->metadata->name;

wait_for("utility pod to be running", sub {
    my $p = $kube->get('Pod', 'demo-utility', namespace => $NS)->get;
    return ($p->status->phase // '') eq 'Running' ? 1 : 0;
}, 60);

# ============================================================
# 18. Full namespace inventory
# ============================================================
say "\n" . "=" x 60;
say "  18. NAMESPACE INVENTORY";
say "=" x 60;

say "\n--- All resources in '$NS' ---";

for my $kind (qw(ConfigMap Secret ServiceAccount Pod Deployment Service Job CronJob
                  PersistentVolumeClaim LimitRange ResourceQuota Role RoleBinding)) {
    my $list = eval { $kube->list($kind, namespace => $NS)->get };
    next unless $list;
    my @items = $list->items->@*;
    next unless @items;
    say "\n  $kind (" . scalar(@items) . "):";
    for my $item (@items) {
        my $name = $item->metadata->name;
        my $created = $item->metadata->creationTimestamp // '';
        printf "    %-40s created=%s\n", $name, $created;
    }
}

# ============================================================
# 19. Serialization demo
# ============================================================
say "\n" . "=" x 60;
say "  19. SERIALIZATION";
say "=" x 60;

my $dep_fresh = $kube->get('Deployment', 'demo-nginx', namespace => $NS)->get;

say "\n--- Deployment as YAML (excerpt) ---";
my $yaml = $dep_fresh->to_yaml;
# Show first 30 lines
my @lines = split /\n/, $yaml;
say "  $_" for @lines[0 .. ($#lines > 29 ? 29 : $#lines)];
say "  ... (" . scalar(@lines) . " lines total)" if @lines > 30;

say "\n--- Deployment as JSON (metadata only) ---";
my $json = JSON::MaybeXS->new(canonical => 1, pretty => 1, utf8 => 1);
my $struct = $dep_fresh->TO_JSON;
say $json->encode({
    apiVersion => $struct->{apiVersion},
    kind       => $struct->{kind},
    metadata   => {
        name      => $struct->{metadata}{name},
        namespace => $struct->{metadata}{namespace},
        labels    => $struct->{metadata}{labels},
        uid       => $struct->{metadata}{uid},
    },
    replicas   => $struct->{spec}{replicas},
    image      => $struct->{spec}{template}{spec}{containers}[0]{image},
});

say "\n--- Round-trip inflate ---";
my $inflated = $rest->inflate($dep_fresh->TO_JSON);
say "  Inflated: " . ref($inflated);
say "  Name: " . $inflated->metadata->name;
say "  Kind: " . $inflated->kind;
say "  Match: " . ($inflated->metadata->uid eq $dep_fresh->metadata->uid ? "YES" : "NO");

# ============================================================
# 20. Quota usage check
# ============================================================
say "\n" . "=" x 60;
say "  20. QUOTA USAGE";
say "=" x 60;

my $q = $kube->get('ResourceQuota', 'namespace-quota', namespace => $NS)->get;
my $used = $q->status->used // {};
$hard = $q->status->hard // {};
say "\n--- Resource usage vs quota ---";
for my $key (sort keys %$hard) {
    printf "  %-30s %s / %s\n", $key, $used->{$key} // '0', $hard->{$key};
}

# ============================================================
# 21. Watch API (async native)
# ============================================================
say "\n" . "=" x 60;
say "  21. WATCH API (async)";
say "=" x 60;

say "\n--- Watching pods in '$NS' (5s window) ---";
my $watch_count = 0;
my $watcher = $kube->watcher('Pod',
    namespace => $NS,
    timeout   => 30,
    on_added  => sub {
        my ($pod) = @_;
        $watch_count++;
        printf "  [ADDED]    %-40s %s\n",
            $pod->metadata->name,
            $pod->status->phase // '?';
    },
    on_modified => sub {
        my ($pod) = @_;
        $watch_count++;
        printf "  [MODIFIED] %-40s %s\n",
            $pod->metadata->name,
            $pod->status->phase // '?';
    },
    on_deleted => sub {
        my ($pod) = @_;
        $watch_count++;
        printf "  [DELETED]  %-40s\n",
            $pod->metadata->name;
    },
);

# Let the watcher collect events for 5 seconds
$loop->watch_time(after => 5, code => sub {
    $watcher->stop;
    $loop->stop;
});
$loop->run;
say "  Received $watch_count events";

# ============================================================
# 22. Cleanup
# ============================================================
say "\n" . "=" x 60;
say "  22. CLEANUP";
say "=" x 60;

say "\n--- Deleting all resources ---";
for my $r (
    ['CronJob',               'demo-cronjob'],
    ['Job',                   'demo-job'],
    ['Pod',                   'demo-utility'],
    ['Service',               'demo-nginx'],
    ['Deployment',            'demo-nginx'],
    ['RoleBinding',           'demo-role-binding'],
    ['Role',                  'demo-role'],
    ['ServiceAccount',        'demo-sa'],
    ['PersistentVolumeClaim', 'demo-storage'],
    ['Secret',                'db-credentials'],
    ['ConfigMap',             'app-config'],
    ['ResourceQuota',         'namespace-quota'],
    ['LimitRange',            'default-limits'],
) {
    my ($kind, $name) = @$r;
    eval { $kube->delete($kind, $name, namespace => $NS)->get };
    printf "  %-25s %-25s %s\n", $kind, $name, $@ ? "SKIP ($@)" : "deleted";
}

say "\n--- Deleting namespace ---";
eval { $kube->delete('Namespace', $NS)->get };
say $@ ? "  SKIP: $@" : "  Namespace '$NS' deleted";

say "\n" . "=" x 60;
say "  DEMO COMPLETE!";
say "=" x 60;
say "";
