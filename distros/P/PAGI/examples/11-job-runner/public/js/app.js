/**
 * Job Runner Dashboard - PAGI Demo
 *
 * Frontend JavaScript for the async job runner application.
 * Demonstrates WebSocket and SSE integration.
 */

(function() {
    'use strict';

    // ===== State =====
    const state = {
        ws: null,
        jobs: {},           // job_id => job object
        jobTypes: [],       // Available job types
        selectedJobType: null,
        selectedJobId: null,
        sseConnection: null, // Current SSE connection for selected job
        reconnectAttempts: 0,
        maxReconnectDelay: 30000,
    };

    // ===== DOM Elements =====
    const elements = {
        connectionStatus: document.getElementById('connection-status'),
        statPending: document.getElementById('stat-pending'),
        statRunning: document.getElementById('stat-running'),
        statCompleted: document.getElementById('stat-completed'),
        statFailed: document.getElementById('stat-failed'),
        jobTypes: document.getElementById('job-types'),
        jobForm: document.getElementById('job-form'),
        jobParams: document.getElementById('job-params'),
        submitBtn: document.getElementById('submit-btn'),
        jobList: document.getElementById('job-list'),
        jobDetails: document.getElementById('job-details'),
        clearCompletedBtn: document.getElementById('clear-completed-btn'),
        workerActive: document.getElementById('worker-active'),
        workerCapacity: document.getElementById('worker-capacity'),
        workerProcessed: document.getElementById('worker-processed'),
    };

    // ===== Connection Status =====
    function setConnectionStatus(status) {
        const el = elements.connectionStatus;
        el.classList.remove('connected', 'disconnected');

        const text = el.querySelector('.status-text');
        switch (status) {
            case 'connected':
                el.classList.add('connected');
                text.textContent = 'Connected';
                break;
            case 'disconnected':
                el.classList.add('disconnected');
                text.textContent = 'Disconnected';
                break;
            default:
                text.textContent = 'Connecting...';
        }
    }

    // ===== WebSocket Connection =====
    function calculateReconnectDelay() {
        const baseDelay = 1000 * Math.pow(2, state.reconnectAttempts);
        const jitter = Math.random() * 1000;
        return Math.min(baseDelay + jitter, state.maxReconnectDelay);
    }

    function connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/queue`;

        setConnectionStatus('connecting');
        state.ws = new WebSocket(wsUrl);

        state.ws.onopen = () => {
            setConnectionStatus('connected');
            state.reconnectAttempts = 0;
        };

        state.ws.onclose = () => {
            setConnectionStatus('disconnected');
            state.reconnectAttempts++;
            const delay = calculateReconnectDelay();
            setTimeout(connectWebSocket, delay);
        };

        state.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        state.ws.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                handleWebSocketMessage(data);
            } catch (e) {
                console.error('Failed to parse message:', e);
            }
        };
    }

    function handleWebSocketMessage(data) {
        switch (data.type) {
            case 'queue_state':
                // Initial state
                state.jobs = {};
                data.jobs.forEach(job => state.jobs[job.id] = job);
                state.jobTypes = data.job_types || [];
                updateStats(data.stats);
                updateWorkerStats(data.worker);
                renderJobTypes();
                renderJobList();
                break;

            case 'job_created':
                // data.data contains the full job object
                state.jobs[data.data.id] = data.data;
                renderJobList();
                updateStatsFromJobs();
                break;

            case 'job_started':
                if (state.jobs[data.data.job_id]) {
                    state.jobs[data.data.job_id].status = 'running';
                    state.jobs[data.data.job_id].started_at = data.data.started_at;
                    renderJobList();
                    updateStatsFromJobs();
                    if (state.selectedJobId === data.data.job_id) {
                        renderJobDetails(data.data.job_id);
                    }
                }
                break;

            case 'job_progress':
                if (state.jobs[data.data.job_id]) {
                    state.jobs[data.data.job_id].progress = {
                        percent: data.data.percent,
                        message: data.data.message,
                    };
                    renderJobList();
                    if (state.selectedJobId === data.data.job_id) {
                        updateJobProgress(data.data.job_id);
                    }
                }
                break;

            case 'job_completed':
                if (state.jobs[data.data.job_id]) {
                    state.jobs[data.data.job_id].status = 'completed';
                    state.jobs[data.data.job_id].result = data.data.result;
                    state.jobs[data.data.job_id].progress = { percent: 100, message: 'Complete' };
                    renderJobList();
                    updateStatsFromJobs();
                    if (state.selectedJobId === data.data.job_id) {
                        renderJobDetails(data.data.job_id);
                    }
                }
                break;

            case 'job_failed':
                if (state.jobs[data.data.job_id]) {
                    state.jobs[data.data.job_id].status = 'failed';
                    state.jobs[data.data.job_id].error = data.data.error;
                    renderJobList();
                    updateStatsFromJobs();
                    if (state.selectedJobId === data.data.job_id) {
                        renderJobDetails(data.data.job_id);
                    }
                }
                break;

            case 'job_cancelled':
                if (state.jobs[data.data.job_id]) {
                    state.jobs[data.data.job_id].status = 'cancelled';
                    renderJobList();
                    updateStatsFromJobs();
                    if (state.selectedJobId === data.data.job_id) {
                        renderJobDetails(data.data.job_id);
                    }
                }
                break;

            case 'jobs_cleared':
                // Remove completed/failed/cancelled jobs from state
                Object.keys(state.jobs).forEach(id => {
                    const job = state.jobs[id];
                    if (['completed', 'failed', 'cancelled'].includes(job.status)) {
                        delete state.jobs[id];
                    }
                });
                if (state.selectedJobId && !state.jobs[state.selectedJobId]) {
                    state.selectedJobId = null;
                    renderJobDetails(null);
                }
                renderJobList();
                updateStatsFromJobs();
                break;

            case 'worker_stats':
                // Update worker stats from broadcast
                updateWorkerStats(data.data);
                break;

            case 'ping':
                // Respond to server ping
                sendWebSocket({ type: 'pong', ts: data.ts });
                break;
        }
    }

    function sendWebSocket(data) {
        if (state.ws && state.ws.readyState === WebSocket.OPEN) {
            state.ws.send(JSON.stringify(data));
        }
    }

    // ===== Stats Updates =====
    function updateStats(stats) {
        elements.statPending.textContent = stats.pending || 0;
        elements.statRunning.textContent = stats.running || 0;
        elements.statCompleted.textContent = stats.completed || 0;
        elements.statFailed.textContent = stats.failed || 0;
    }

    function updateStatsFromJobs() {
        const stats = { pending: 0, running: 0, completed: 0, failed: 0, cancelled: 0 };
        Object.values(state.jobs).forEach(job => {
            if (stats[job.status] !== undefined) {
                stats[job.status]++;
            }
        });
        updateStats(stats);
    }

    function updateWorkerStats(worker) {
        if (worker) {
            elements.workerActive.textContent = worker.active || 0;
            elements.workerCapacity.textContent = worker.capacity || 3;
            elements.workerProcessed.textContent = worker.processed || 0;
        }
    }

    // ===== Job Types =====
    function renderJobTypes() {
        elements.jobTypes.innerHTML = state.jobTypes.map(type => `
            <button type="button" class="job-type-btn" data-type="${escapeHtml(type.name)}">
                <span class="job-type-name">${escapeHtml(type.name)}</span>
                <span class="job-type-desc">${escapeHtml(type.description)}</span>
            </button>
        `).join('');

        // Add click handlers
        elements.jobTypes.querySelectorAll('.job-type-btn').forEach(btn => {
            btn.addEventListener('click', () => selectJobType(btn.dataset.type));
        });
    }

    function selectJobType(typeName) {
        state.selectedJobType = state.jobTypes.find(t => t.name === typeName);

        // Update button states
        elements.jobTypes.querySelectorAll('.job-type-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.type === typeName);
        });

        // Render form
        renderJobForm();
    }

    function renderJobForm() {
        if (!state.selectedJobType) {
            elements.jobParams.innerHTML = '<p class="placeholder-text">Select a job type above</p>';
            elements.submitBtn.disabled = true;
            return;
        }

        const params = state.selectedJobType.params || [];

        elements.jobParams.innerHTML = params.map(param => `
            <div class="form-group">
                <label for="param-${escapeHtml(param.name)}">${escapeHtml(param.name)}</label>
                <input type="${param.type === 'integer' ? 'number' : 'text'}"
                       id="param-${escapeHtml(param.name)}"
                       name="${escapeHtml(param.name)}"
                       value="${param.default !== undefined ? param.default : ''}"
                       ${param.min !== undefined ? `min="${param.min}"` : ''}
                       ${param.max !== undefined ? `max="${param.max}"` : ''}>
                ${param.description ? `<span class="hint">${escapeHtml(param.description)}</span>` : ''}
            </div>
        `).join('');

        elements.submitBtn.disabled = false;
    }

    // ===== Job List =====
    function renderJobList() {
        const jobs = Object.values(state.jobs);

        // Sort: running first, then pending, then by ID descending
        jobs.sort((a, b) => {
            const statusOrder = { running: 0, pending: 1, completed: 2, failed: 2, cancelled: 2 };
            const aOrder = statusOrder[a.status] ?? 3;
            const bOrder = statusOrder[b.status] ?? 3;
            if (aOrder !== bOrder) return aOrder - bOrder;
            return b.id - a.id;
        });

        if (jobs.length === 0) {
            elements.jobList.innerHTML = '<p class="placeholder-text">No jobs in queue</p>';
            return;
        }

        elements.jobList.innerHTML = jobs.map(job => `
            <div class="job-card ${state.selectedJobId === job.id ? 'selected' : ''}" data-job-id="${job.id}">
                <div class="job-card-header">
                    <span class="job-id">#${job.id}</span>
                    <span class="job-type">${escapeHtml(job.type)}</span>
                    <span class="job-status ${job.status}">${job.status}</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill ${job.status}" style="width: ${job.progress?.percent || 0}%"></div>
                </div>
                <div class="progress-message">${escapeHtml(job.progress?.message || '')}</div>
            </div>
        `).join('');

        // Add click handlers
        elements.jobList.querySelectorAll('.job-card').forEach(card => {
            card.addEventListener('click', () => selectJob(parseInt(card.dataset.jobId)));
        });
    }

    function selectJob(jobId) {
        state.selectedJobId = jobId;
        renderJobList();
        renderJobDetails(jobId);
        connectSSE(jobId);
    }

    // ===== Job Details =====
    function renderJobDetails(jobId) {
        if (!jobId || !state.jobs[jobId]) {
            elements.jobDetails.innerHTML = '<p class="placeholder-text">Select a job to view details</p>';
            return;
        }

        const job = state.jobs[jobId];

        let resultHtml = '';
        if (job.status === 'completed' && job.result) {
            resultHtml = `
                <div class="detail-section">
                    <h3>Result</h3>
                    <div class="result-box">${escapeHtml(JSON.stringify(job.result, null, 2))}</div>
                </div>
            `;
        } else if (job.status === 'failed' && job.error) {
            resultHtml = `
                <div class="detail-section">
                    <h3>Error</h3>
                    <div class="error-box">${escapeHtml(job.error)}</div>
                </div>
            `;
        }

        elements.jobDetails.innerHTML = `
            <div class="detail-section">
                <h3>Job #${job.id}</h3>
                <div class="detail-row">
                    <span class="detail-label">Type</span>
                    <span class="detail-value">${escapeHtml(job.type)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Status</span>
                    <span class="job-status ${job.status}">${job.status}</span>
                </div>
            </div>

            <div class="detail-section">
                <h3>Progress</h3>
                <div class="progress-bar progress-large">
                    <div class="progress-fill ${job.status}" id="detail-progress-fill"
                         style="width: ${job.progress?.percent || 0}%">
                        ${job.progress?.percent || 0}%
                    </div>
                </div>
                <div id="detail-progress-message">${escapeHtml(job.progress?.message || '')}</div>
            </div>

            <div class="detail-section">
                <h3>Parameters</h3>
                <div class="result-box">${escapeHtml(JSON.stringify(job.params || {}, null, 2))}</div>
            </div>

            ${resultHtml}

            ${['pending', 'running'].includes(job.status) ? `
                <button class="btn btn-danger" id="cancel-job-btn">Cancel Job</button>
            ` : ''}
        `;

        // Add cancel handler
        const cancelBtn = document.getElementById('cancel-job-btn');
        if (cancelBtn) {
            cancelBtn.addEventListener('click', () => cancelJob(jobId));
        }
    }

    function updateJobProgress(jobId) {
        const job = state.jobs[jobId];
        if (!job) return;

        const progressFill = document.getElementById('detail-progress-fill');
        const progressMessage = document.getElementById('detail-progress-message');

        if (progressFill) {
            progressFill.style.width = `${job.progress?.percent || 0}%`;
            progressFill.textContent = `${job.progress?.percent || 0}%`;
        }
        if (progressMessage) {
            progressMessage.textContent = job.progress?.message || '';
        }
    }

    // ===== SSE Connection =====
    function connectSSE(jobId) {
        // Close existing connection
        if (state.sseConnection) {
            state.sseConnection.close();
            state.sseConnection = null;
        }

        if (!jobId) return;

        const job = state.jobs[jobId];
        if (!job || ['completed', 'failed', 'cancelled'].includes(job.status)) {
            return; // No need to stream for finished jobs
        }

        // Connect SSE for real-time progress
        state.sseConnection = new EventSource(`/api/jobs/${jobId}/progress`);

        state.sseConnection.addEventListener('progress', (event) => {
            const data = JSON.parse(event.data);
            if (state.jobs[jobId]) {
                state.jobs[jobId].progress = data;
                renderJobList();
                if (state.selectedJobId === jobId) {
                    updateJobProgress(jobId);
                }
            }
        });

        state.sseConnection.addEventListener('complete', (event) => {
            const data = JSON.parse(event.data);
            if (state.jobs[jobId]) {
                state.jobs[jobId].status = 'completed';
                state.jobs[jobId].result = data.result;
                state.jobs[jobId].progress = { percent: 100, message: 'Complete' };
                renderJobList();
                updateStatsFromJobs();
                if (state.selectedJobId === jobId) {
                    renderJobDetails(jobId);
                }
            }
            state.sseConnection.close();
            state.sseConnection = null;
        });

        state.sseConnection.addEventListener('failed', (event) => {
            const data = JSON.parse(event.data);
            if (state.jobs[jobId]) {
                state.jobs[jobId].status = 'failed';
                state.jobs[jobId].error = data.error;
                renderJobList();
                updateStatsFromJobs();
                if (state.selectedJobId === jobId) {
                    renderJobDetails(jobId);
                }
            }
            state.sseConnection.close();
            state.sseConnection = null;
        });

        state.sseConnection.onerror = () => {
            state.sseConnection.close();
            state.sseConnection = null;
        };
    }

    // ===== Actions =====
    function createJob(type, params) {
        sendWebSocket({
            type: 'create_job',
            job_type: type,
            params: params,
        });
    }

    function cancelJob(jobId) {
        sendWebSocket({
            type: 'cancel_job',
            job_id: jobId,
        });
    }

    function clearCompleted() {
        sendWebSocket({
            type: 'clear_completed',
        });
    }

    // ===== Event Handlers =====
    function initEventHandlers() {
        // Job form submission
        elements.jobForm.addEventListener('submit', (e) => {
            e.preventDefault();
            if (!state.selectedJobType) return;

            const params = {};
            state.selectedJobType.params.forEach(param => {
                const input = document.getElementById(`param-${param.name}`);
                if (input) {
                    let value = input.value;
                    if (param.type === 'integer') {
                        value = parseInt(value);
                    }
                    params[param.name] = value;
                }
            });

            createJob(state.selectedJobType.name, params);
        });

        // Clear completed button
        elements.clearCompletedBtn.addEventListener('click', clearCompleted);
    }

    // ===== Utilities =====
    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        const div = document.createElement('div');
        div.textContent = String(text);
        return div.innerHTML;
    }

    // ===== Initialization =====
    function init() {
        initEventHandlers();
        connectWebSocket();
    }

    document.addEventListener('DOMContentLoaded', init);
})();
