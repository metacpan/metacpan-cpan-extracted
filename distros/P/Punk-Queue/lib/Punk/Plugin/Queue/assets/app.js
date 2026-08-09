/* punk-queue admin - the page modules.
 *
 * Server-rendered pages navigated as an SPA (Funky.SPA swaps
 * #spaContent), one Funky.Pages module per page.
 *
 * Refresh is a 5s poll: the stats, and the current page's own view
 * (its table, or the job it is showing). That poll is the load-bearing
 * one - a job changes state inside a WORKER process, which has no way
 * to reach these sockets. Live mode is the enhancement on top: a
 * websocket carrying what this web process itself did (an enqueue, a
 * retry, a remove), bridged into Funky.Pages.handleDataChange so the
 * page reacts immediately instead of on the next tick. The bridge is
 * ours - Pages documents handleDataChange but nothing in Funky calls it.
 *
 * ES5, no build step, matching the framework it drives. */
(function () {
	'use strict';

	if (!window.Funky || !Funky.Pages || !Funky.SPA) {
		if (window.console) console.error('[punk-queue] Funky did not load');
		return;
	}

	var PQ = window.__PQ || { prefix: '', live: false };
	var API = PQ.prefix + '/api';

	function get(url, params) { return Funky.Api.get(url, params || {}); }
	function post(url, data) {
		if (window.__pqCsrfMirror) window.__pqCsrfMirror();
		return Funky.Api.post(url, data || {});
	}

	function fail(container, err) {
		Funky.EmptyState.show(container, {
			type: 'error',
			title: 'Could not load',
			message: (err && err.message) || 'the endpoint returned an error'
		});
	}

	function stateBadge(s) {
		return '<span class="pq-state pq-state-' + s + '">' + s + '</span>';
	}
	function esc(s) {
		return String(s == null ? '' : s)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
	}

	/* ---- the page's table ------------------------------------------------
	 *
	 * Whichever table the current page owns, so the poll below can refresh
	 * it. Live mode cannot: a push only ever carries what THIS process did
	 * (enqueue, retry, remove, stop, cron run). The transitions worth
	 * watching - a worker claiming a job, finishing it, failing it, a
	 * backoff coming due, the scheduler firing - happen in a worker
	 * process that has no handle on these sockets. Without the refresh a
	 * pushed row appears and then sits at `inactive` forever.
	 *
	 * It runs only when the stats signature below says something moved,
	 * so an idle queue rebuilds nothing. Each refresher reports whether it
	 * actually re-read: a skipped one must not be mistaken for an
	 * up-to-date page, or the change it deferred is lost. */
	var activeRefresh = null;
	function refreshActive() {
		if (!activeRefresh || document.hidden) return false;
		try { return activeRefresh(); } catch (e) { return false; }
	}
	/* a table's re-read: skipped while rows are selected, so a refresh
	 * never pulls the ground out from under a bulk action */
	function tableRefresher(get) {
		return function () {
			var t = get();
			if (!t || (t.selectedIds && t.selectedIds.size)) return false;
			t.reload();
			return true;
		};
	}

	/* Relative times are hydrated by Funky.RelativeTime, which scans on
	 * funky.spa.pageload and on a `funky.datatable.draw` DOM event. Funky
	 * .Table emits `funky:table:draw` on PubSub instead - a different name
	 * on a different bus - so rows drawn by a reload keep an empty <time>.
	 * The bridge is one line, like the entity_change one. */
	if (Funky.PubSub && Funky.RelativeTime && Funky.RelativeTime.init) {
		Funky.PubSub.on('funky:table:draw', function (e) {
			var el = e && e.table && e.table.container;
			Funky.RelativeTime.init(el || undefined);
		});
	}

	/* ---- stats poll (all pages) + live indicator ------------------------ */

	/* the overview's by-queue / by-task tables, fed by the same stats
	 * poll: plain markup on Funky's .funky-table styles, each name a
	 * link into the filtered jobs page */
	function renderBreakdown(id, groups, param) {
		var el = document.getElementById(id);
		if (!el) return;
		var names = [], k;
		for (k in groups) if (groups.hasOwnProperty(k)) names.push(k);
		names.sort();
		if (!names.length) {
			el.innerHTML = '<p class="pq-breakdown-empty">nothing yet</p>';
			return;
		}
		var html = '<div class="pq-breakdown-scroll">' +
			'<table class="funky-table pq-breakdown"><thead><tr>' +
			'<th>' + (param === 'queue' ? 'Queue' : 'Task') + '</th>' +
			'<th>Inactive</th><th>Active</th><th>Failed</th>' +
			'<th>Finished</th><th>Total</th></tr></thead><tbody>';
		for (var i = 0; i < names.length; i++) {
			var g = groups[names[i]] || {};
			var ia = g.inactive || 0, ac = g.active || 0,
			    fl = g.failed || 0, fn = g.finished || 0;
			/* title as well as text: a name is an identifier, so it stays
			 * readable even if a custom stylesheet decides to clip it */
			html += '<tr>' +
				'<td><a href="#" title="' + esc(names[i]) +
					'" data-name="' + esc(names[i]) + '">' +
					esc(names[i]) + '</a></td>' +
				'<td>' + ia + '</td><td>' + ac + '</td>' +
				'<td>' + (fl ? '<span class="pq-breakdown-bad">' + fl +
					'</span>' : 0) + '</td>' +
				'<td>' + fn + '</td>' +
				'<td>' + (ia + ac + fl + fn) + '</td></tr>';
		}
		el.innerHTML = html + '</tbody></table></div>';
	}

	/* The change signal. /api/stats is already fetched every tick, and it
	 * is one indexed GROUP BY - far cheaper than a page of job rows and
	 * their JSON columns. Nothing in the queue moved unless one of these
	 * counters moved, so this is what decides whether the page re-reads
	 * itself at all. An idle queue then costs one stats request per tick
	 * and touches no DOM: no rebuilt rows, no dropped hover or focus, no
	 * re-created <time> nodes. */
	var lastSig = null;
	function statsSignature(s) {
		return [s.inactive_jobs, s.active_jobs, s.failed_jobs,
			s.finished_jobs, s.delayed_jobs, s.enqueued_jobs,
			s.total_jobs, s.workers, s.active_workers].join(':');
	}

	var pollTimer = null;
	function pollStats() {
		get(API + '/stats').then(function (s) {
			var el;
			var sig = statsSignature(s);
			if (sig !== lastSig) {
				/* The first tick only establishes the baseline - the page
				 * has just read itself. After that the signature is
				 * accepted ONLY once the page really did re-read: a hidden
				 * tab or an open selection must defer the refresh, not
				 * swallow it. */
				if (lastSig === null || refreshActive()) lastSig = sig;
			}
			if (Funky.StatsBar.getInstance && Funky.StatsBar.getInstance('pqStats'))
				Funky.StatsBar.update('pqStats', {
					inactive: s.inactive_jobs, active: s.active_jobs,
					failed: s.failed_jobs, delayed: s.delayed_jobs,
					finished: s.finished_jobs
				});
			renderBreakdown('pqQueues', s.queues, 'queue');
			renderBreakdown('pqTasks',  s.tasks,  'task');
			if ((el = document.getElementById('pqSchema')))
				el.textContent = s.schema_version;
			if ((el = document.getElementById('pqWorkersAlive')))
				el.textContent = s.active_workers + ' / ' + s.workers;
			if ((el = document.getElementById('pqEnqueued')))
				el.textContent = s.enqueued_jobs;
		})['catch'](function () { /* the poll retries in 5s anyway */ });
	}
	function startPolling() {
		if (pollTimer) return;
		pollTimer = setInterval(pollStats, 5000);
		if (Funky.VisibilityObserver && Funky.VisibilityObserver.init)
			Funky.VisibilityObserver.init();
		document.addEventListener('visibilitychange', function () {
			if (!document.hidden) pollStats();
		});
	}

	/* ---- overview ------------------------------------------------------- */

	Funky.Pages.register('pq-overview', {
		entities: ['stats', 'job'],
		init: function () {
			Funky.StatsBar.init('#pqStats', { id: 'pqStats', stats: [
				{ id: 'inactive', icon: 'fa-inbox',              label: 'Inactive', variant: 'secondary' },
				{ id: 'active',   icon: 'fa-play-circle',        label: 'Active',   variant: 'info' },
				{ id: 'failed',   icon: 'fa-exclamation-circle', label: 'Failed',   variant: 'danger' },
				{ id: 'delayed',  icon: 'fa-clock',              label: 'Delayed',  variant: 'warning' },
				{ id: 'finished', icon: 'fa-check-circle',       label: 'Finished', variant: 'success' }
			]});
			/* each stat links to the filtered jobs page */
			var bar = document.getElementById('pqStats');
			if (bar) bar.addEventListener('click', function (e) {
				var stat = e.target.closest ? e.target.closest('.stat-item') : null;
				var id = stat && stat.getAttribute('data-stat-id');
				if (id && id !== 'delayed')
					Funky.SPA.navigate(PQ.prefix + '/jobs?state=' +
						(id === 'inactive' ? 'inactive' : id));
			});
			/* breakdown names too - delegated on the containers, which
			 * survive the poll's innerHTML replacements */
			var wire = function (id, param) {
				var el = document.getElementById(id);
				if (el) el.addEventListener('click', function (e) {
					var a = e.target.closest ?
						e.target.closest('a[data-name]') : null;
					if (!a) return;
					e.preventDefault();
					Funky.SPA.navigate(PQ.prefix + '/jobs?' + param + '=' +
						encodeURIComponent(a.getAttribute('data-name')));
				});
			};
			wire('pqQueues', 'queue');
			wire('pqTasks',  'task');
			pollStats();
			get(API + '/history').then(function (h) {
				var el = document.getElementById('pqHistory');
				if (!el) return;
				var buckets = h.hourly || [];
				if (!buckets.length) {
					Funky.EmptyState.show(el, { type: 'no-data',
						title: 'No history yet',
						message: 'finished and failed jobs appear here' });
					return;
				}
				var fin = [], bad = [];
				for (var i = 0; i < buckets.length; i++) {
					fin.push(buckets[i].finished || 0);
					bad.push(buckets[i].failed || 0);
				}
				el.innerHTML =
					'<div>finished <span data-sparkline="bar" data-values="' +
						fin.join(',') + '" data-width="360" data-height="48"></span></div>' +
					'<div>failed <span data-sparkline="bar" data-values="' +
						bad.join(',') + '" data-width="360" data-height="48" data-color="var(--pro-accent-danger, #f85149)"></span></div>';
				Funky.Charts.autoInit(el);
			})['catch'](function (e) { fail(document.getElementById('pqHistory'), e); });
		},
		destroy: function () { return {}; }
	});

	/* ---- jobs ----------------------------------------------------------- */

	var jobsTable = null;

	Funky.Pages.register('pq-jobs', {
		entities: ['job'],
		init: function () {
			var initial = {};
			var qs = window.location.search.replace(/^\?/, '').split('&');
			for (var i = 0; i < qs.length; i++) {
				var kv = qs[i].split('=');
				if (kv[0] && /^(state|queue|task|worker)$/.test(kv[0]))
					initial[kv[0]] = decodeURIComponent(kv[1] || '');
			}

			jobsTable = Funky.Table.init('#pqJobsTable', {
				tableName: 'jobs',
				ajax: { url: API + '/jobs' },     /* object form: serverSide
				                                   * silently downgrades with
				                                   * ajaxUrl (table.js:300) */
				serverSide: true,
				select: 'multi',
				pageLength: 25,
				extraAjaxData: initial,
				columns: [
					/* the id is the way INTO a job, so it renders as a
					 * link. data-action keeps Funky's _handleClick from
					 * treating the click as row selection - a mouse click
					 * on a selectable table only ever selects; onRowClick
					 * below fires from keyboard activation (Enter) alone */
					{ data: 'id',       title: 'ID',    name: 'id',
					  render: function (v) {
						return '<a href="' + PQ.prefix + '/jobs/' + v +
							'" data-action="view">' + v + '</a>';
					  } },
					{ data: 'task',     title: 'Task',  name: 'task' },
					{ data: 'queue',    title: 'Queue', name: 'queue' },
					{ data: 'state',    title: 'State', name: 'state',
					  render: function (v) { return stateBadge(v); } },
					{ data: 'priority', title: 'Pri',   name: 'priority' },
					/* retries is zero-based (completed re-runs, the guard's
					 * raw value); people count attempts from 1, and the
					 * log's lifecycle rows already do - keep them agreeing */
					{ data: 'retries',  title: 'Try',   orderable: false,
					  render: function (v, type, row) { return (v + 1) + '/' + row.attempts; } },
					{ data: 'created',  title: 'Created', name: 'created',
					  render: function (v) {
						return '<time data-relative datetime="' +
							new Date(v * 1000).toISOString() + '"></time>';
					  } }
				],
				onRowClick: function (row) {
					Funky.SPA.navigate(PQ.prefix + '/jobs/' + row.id);
				}
			});
			activeRefresh = tableRefresher(function () { return jobsTable; });

			/* NO click listener for the view links: SPA.bindNavigation
			 * already intercepts every same-origin a[href] at the
			 * document. A second navigate() here races it - the two URL
			 * spellings (attribute vs link.href) slip the concurrent-load
			 * guard, and the doubled showLoading orphans a spinner timer
			 * that nothing clears: the stuck "Loading..." bug. The link
			 * only needs data-action, which keeps Funky.Table's selection
			 * handler off it; SPA does the rest. */

			/* the filter toolbar does not talk to Funky.Table (its
			 * dataTable integration is jQuery-era) - wire it by hand */
			var bar = document.getElementById('pqJobsFilters');
			if (bar) {
				var html = '';
				var selects = {
					state: ['', 'inactive', 'active', 'finished', 'failed'],
					queue: null, task: null
				};
				html += '<label>state <select data-pq-filter="state">';
				for (var s = 0; s < selects.state.length; s++)
					html += '<option' + (initial.state === selects.state[s] ? ' selected' : '') + '>' +
						selects.state[s] + '</option>';
				html += '</select></label>';
				html += '<label>queue <input size="12" data-pq-filter="queue" value="' + esc(initial.queue) + '"></label>';
				html += '<label>task <input size="16" data-pq-filter="task" value="' + esc(initial.task) + '"></label>';
				bar.innerHTML = html;
				bar.addEventListener('change', function (e) {
					var k = e.target.getAttribute('data-pq-filter');
					if (!k) return;
					var v = e.target.value;
					if (v) jobsTable.setFilter(k, v);
					else jobsTable.clearFilter(k);
				});
			}

			Funky.BulkActions.create({
				table: jobsTable,
				actions: [
					{ id: 'retry',  label: 'Retry',  icon: 'fa-redo',  variant: 'primary' },
					{ id: 'remove', label: 'Remove', icon: 'fa-trash', variant: 'danger' }
				],
				onAction: function (actionId, items) {
					var ids = [], byTask = {}, t;
					for (var i = 0; i < items.length; i++) {
						ids.push(items[i].id);
						byTask[items[i].task] = (byTask[items[i].task] || 0) + 1;
					}
					var breakdown = [];
					for (t in byTask) breakdown.push(byTask[t] + ' x ' + t);
					Funky.Modal.confirm({
						title: actionId + ' ' + ids.length + ' job(s)?',
						message: 'Selection: ' + breakdown.join(', ') +
							'. This acts on exactly the rows you selected.',
						onConfirm: function () {
							post(API + '/jobs/bulk', { action: actionId, ids: ids })
								.then(function (r) {
									Funky.Toast.success(actionId + ': ' +
										r.succeeded + ' ok, ' + r.failed + ' not');
									jobsTable.deselectAll();
									jobsTable.reload();
								})['catch'](function (e) {
									Funky.Toast.error((e && e.message) || 'bulk failed');
								});
						}
					});
				}
			});
		},
		update: function () { if (jobsTable) jobsTable.reload(); },
		destroy: function () { jobsTable = null; activeRefresh = null; return {}; }
	});

	/* ---- job detail ------------------------------------------------------ */

	Funky.Pages.register('pq-job', {
		entities: ['job'],
		init: function () {
			var el = document.getElementById('pqJobDetail');
			if (!el) return;
			var id = el.getAttribute('data-job-id');

			function pad(n) { return n < 10 ? '0' + n : n; }
			function renderLog() {
				var box = document.getElementById('pqJobLog');
				if (!box) return;
				get(API + '/jobs/' + id + '/log').then(function (r) {
					var log = r.log || [];
					if (!log.length) {
						box.innerHTML = '<p class="pq-breakdown-empty">' +
							'no log lines yet</p>';
						return;
					}
					var html = '<table class="funky-table pq-joblog"><tbody>';
					for (var i = 0; i < log.length; i++) {
						var d = new Date((log[i].created || 0) * 1000);
						html += '<tr>' +
							'<td class="pq-joblog-time">' +
								pad(d.getHours()) + ':' + pad(d.getMinutes()) +
								':' + pad(d.getSeconds()) + '</td>' +
							'<td><span class="pq-loglevel pq-loglevel-' +
								esc(log[i].level) + '">' + esc(log[i].level) +
								'</span></td>' +
							'<td class="pq-joblog-msg">' + esc(log[i].message) +
								'</td></tr>';
					}
					box.innerHTML = html + '</tbody></table>';
				})['catch'](function (e) { fail(box, e); });
			}

			function render() {
				renderLog();
				get(API + '/jobs/' + id).then(function (j) {
					var parents = '';
					if (j.parents && j.parents.length) {
						for (var i = 0; i < j.parents.length; i++)
							parents += '<a href="' + PQ.prefix + '/jobs/' +
								j.parents[i] + '">' + j.parents[i] + '</a> ';
					} else parents = '-';
					el.innerHTML =
						'<dl>' +
						'<dt>task</dt><dd>' + esc(j.task) + '</dd>' +
						'<dt>queue</dt><dd>' + esc(j.queue) + '</dd>' +
						'<dt>state</dt><dd>' + stateBadge(j.state) + '</dd>' +
						'<dt>priority</dt><dd>' + j.priority + '</dd>' +
						'<dt>attempt</dt><dd>' + (j.retries + 1) + '/' + j.attempts + '</dd>' +
						'<dt>parents</dt><dd>' + parents + '</dd>' +
						'<dt>args</dt><dd><pre>' + esc(JSON.stringify(j.args, null, 1)) + '</pre></dd>' +
						'<dt>result</dt><dd><pre>' + esc(JSON.stringify(j.result, null, 1)) + '</pre></dd>' +
						'<dt>notes</dt><dd><pre>' + esc(JSON.stringify(j.notes, null, 1)) + '</pre></dd>' +
						'</dl>';
				})['catch'](function (e) { fail(el, e); });
			}
			render();
			/* a job page is opened to watch a job: same 5s tick as the
			 * tables, for the same reason - the transitions happen in a
			 * worker, which cannot push */
			activeRefresh = function () { render(); return true; };

			var retry = document.getElementById('pqJobRetry');
			var remove = document.getElementById('pqJobRemove');
			if (retry) retry.addEventListener('click', function () {
				post(API + '/jobs/' + id + '/retry').then(function () {
					Funky.Toast.success('job ' + id + ' retried');
					render();
				})['catch'](function (e) { Funky.Toast.error(e.message || 'retry failed'); });
			});
			if (remove) remove.addEventListener('click', function () {
				Funky.Modal.confirm({
					title: 'Remove job ' + id + '?',
					message: 'An active job is refused; retry it first.',
					onConfirm: function () {
						post(API + '/jobs/' + id + '/remove').then(function () {
							Funky.Toast.success('job ' + id + ' removed');
							Funky.SPA.navigate(PQ.prefix + '/jobs');
						})['catch'](function (e) { Funky.Toast.error(e.message || 'remove failed'); });
					}
				});
			});
		},
		update: function () { if (activeRefresh) activeRefresh(); },
		destroy: function () { activeRefresh = null; return {}; }
	});

	/* ---- workers / locks / crons ---------------------------------------- */

	var workersTable = null;
	Funky.Pages.register('pq-workers', {
		entities: ['worker'],
		init: function () {
			workersTable = Funky.Table.init('#pqWorkersTable', {
				tableName: 'workers',
				ajax: { url: API + '/workers' },
				serverSide: true,
				columns: [
					{ data: 'id',   title: 'ID' },
					{ data: 'host', title: 'Host', orderable: false },
					{ data: 'pid',  title: 'PID', orderable: false },
					{ data: 'role', title: 'Role', orderable: false },
					{ data: 'queues', title: 'Queues', orderable: false,
					  render: function (v) { return esc((v || []).join(', ')); } },
					{ data: 'notified', title: 'Heartbeat', orderable: false,
					  render: function (v, type, row) {
						var stale = (Date.now() / 1000 - v) > 60;
						return '<time data-relative datetime="' +
							new Date(v * 1000).toISOString() + '"></time>' +
							(stale ? ' <span class="pq-stale">stale</span>' : '');
					  } },
					{ data: 'id', title: '', orderable: false, name: '_stop',
					  render: function (v, type, row) {
						return row.role === 'supervisor' ? '' :
							'<button class="btn btn-sm" data-action="stop" data-worker="' + v + '">stop</button>';
					  } }
				]
			});
			activeRefresh = tableRefresher(function () { return workersTable; });
			var el = document.getElementById('pqWorkersTable');
			if (el) el.addEventListener('click', function (e) {
				if (e.target.getAttribute('data-action') !== 'stop') return;
				var wid = e.target.getAttribute('data-worker');
				post(API + '/workers/' + wid + '/stop').then(function () {
					Funky.Toast.success('stop sent to worker ' + wid);
				})['catch'](function (er) { Funky.Toast.error(er.message || 'stop failed'); });
			});
		},
		update: function () { if (workersTable) workersTable.reload(); },
		destroy: function () { workersTable = null; activeRefresh = null; return {}; }
	});

	var locksTable = null;
	Funky.Pages.register('pq-locks', {
		entities: ['lock'],
		init: function () {
			locksTable = Funky.Table.init('#pqLocksTable', {
				tableName: 'locks',
				ajax: { url: API + '/locks' },
				serverSide: true,
				columns: [
					{ data: 'id', title: 'ID' },
					{ data: 'name', title: 'Name', orderable: false },
					{ data: 'owner', title: 'Owner', orderable: false,
					  render: function (v) { return v == null ? '-' : v; } },
					{ data: 'expires', title: 'Expires', orderable: false,
					  render: function (v) {
						return '<time data-relative datetime="' +
							new Date(v * 1000).toISOString() + '"></time>';
					  } }
				]
			});
			activeRefresh = tableRefresher(function () { return locksTable; });
		},
		update: function () { if (locksTable) locksTable.reload(); },
		destroy: function () { locksTable = null; activeRefresh = null; return {}; }
	});

	var cronsTable = null;
	Funky.Pages.register('pq-crons', {
		entities: ['cron'],
		init: function () {
			cronsTable = Funky.Table.init('#pqCronsTable', {
				tableName: 'crons',
				ajax: { url: API + '/crons' },
				serverSide: true,
				columns: [
					{ data: 'name', title: 'Name', orderable: false },
					{ data: 'expr', title: 'Expression', orderable: false },
					{ data: 'task', title: 'Task', orderable: false },
					{ data: 'queue', title: 'Queue', orderable: false },
					{ data: 'enabled', title: 'Enabled', orderable: false,
					  render: function (v) {
						return v ? '<span class="pq-state pq-state-finished">on</span>'
						         : '<span class="pq-state pq-state-failed">off</span>';
					  } },
					{ data: 'next_run', title: 'Next', orderable: false,
					  render: function (v, type, row) {
						if (!row.enabled || v == null) return '-';
						return '<time data-relative datetime="' +
							new Date(v * 1000).toISOString() + '"></time>';
					  } },
					{ data: 'name', title: '', orderable: false, name: '_ops',
					  render: function (v, type, row) {
						return '<button class="btn btn-sm" data-action="run" data-cron="' +
							esc(v) + '">run now</button> ' +
							'<button class="btn btn-sm" data-action="' +
							(row.enabled ? 'disable' : 'enable') +
							'" data-cron="' + esc(v) + '">' +
							(row.enabled ? 'disable' : 'enable') + '</button>';
					  } }
				]
			});
			activeRefresh = tableRefresher(function () { return cronsTable; });
			var el = document.getElementById('pqCronsTable');
			if (el) el.addEventListener('click', function (e) {
				var action = e.target.getAttribute('data-action');
				if (!action) return;
				var name = e.target.getAttribute('data-cron');
				post(API + '/crons/' + encodeURIComponent(name) + '/' + action)
					.then(function (r) {
						Funky.Toast.success(action === 'run'
							? 'enqueued job ' + r.id : name + ' ' + action + 'd');
						if (cronsTable) cronsTable.reload();
					})['catch'](function (er) {
						Funky.Toast.error(er.message || action + ' failed');
					});
			});
		},
		update: function () { if (cronsTable) cronsTable.reload(); },
		destroy: function () { cronsTable = null; activeRefresh = null; return {}; }
	});

	/* ---- boot ------------------------------------------------------------ */

	Funky.SPA.init();
	startPolling();

	/* the entity bridge: Funky documents Pages.handleDataChange but
	 * nothing calls it - the websocket envelope is ours. Server sends
	 * { type: 'entity_change', entity, action, id }. */
	if (PQ.live && Funky.WebSocket) {
		/* the URL goes in through init, NOT connect: Funky.WebSocket.connect
		 * takes no arguments and reads CONFIG.url, whose default is
		 * /ws/realtime - a route this app does not have. Passing it to
		 * connect() is silently ignored and every attempt 404s. */
		var proto = location.protocol === 'https:' ? 'wss://' : 'ws://';
		Funky.WebSocket.init({
			url: proto + location.host + PQ.prefix + '/ws',
			presenceEnabled: false,     /* no presence protocol on this route */
			debug: false
		});
		Funky.WebSocket.on('entity_change', function (m) {
			Funky.Pages.handleDataChange(m.entity, m.id, m.action || 'refresh', m);
			if (m.entity === 'stats') pollStats();
		});

		/* the badge follows the connection rather than announcing it: live
		 * mode is an enhancement over the poll, and a socket that never
		 * came up must not leave the page claiming it did */
		document.addEventListener('funky.ws.status', function (e) {
			var el = document.getElementById('pqLive');
			var on = e.detail && e.detail.status === 'connected';
			if (!el) return;
			el.textContent = on ? 'live' : 'polling';
			el.setAttribute('data-live', on ? 'on' : 'off');
		});

		Funky.WebSocket.connect();
	}

	/* boot-time completeness assertion - missing modules otherwise fail
	 * silently at first call (the vendoring gotcha made executable) */
	(function () {
		var need = ['Dom', 'Pages', 'SPA', 'Api', 'Table', 'StatsBar', 'Charts',
			'Toast', 'Modal', 'EmptyState', 'BulkActions', 'RelativeTime'];
		for (var i = 0; i < need.length; i++)
			if (!Funky[need[i]] && window.console)
				console.error('[punk-queue] missing Funky module: ' + need[i]);
	})();

	/* the current page module (full page load; SPA handles later swaps) */
	var content = document.getElementById('spaContent');
	if (content) {
		var pageId = content.getAttribute('data-page');
		if (pageId && Funky.Pages.has(pageId)) Funky.Pages.mount(pageId);
	}
	if (Funky.RelativeTime && Funky.RelativeTime.init) Funky.RelativeTime.init();
})();
