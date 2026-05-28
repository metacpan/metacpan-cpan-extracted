function initAIChat() {
    var container = document.getElementById('ai-chat-container');
    if (!container) return;
    if (container.dataset.aiChatInitialized) return;
    container.dataset.aiChatInitialized = '1';

    var messagesDiv = document.getElementById('ai-chat-messages');
    var input = document.getElementById('ai-chat-input');
    var sendBtn = document.getElementById('ai-chat-send');
    var sessionId = document.getElementById('ai-chat-session-id').value;
    var applySection = document.getElementById('ai-chat-apply-section');
    var applyBtn = document.getElementById('ai-chat-apply');
    var previewDiv = document.getElementById('ai-chat-initialdata-preview');
    var resultsDiv = document.getElementById('ai-chat-apply-results');
    var rawJsonContent = document.getElementById('ai-chat-raw-json-content');

    var userAvatarHtml = container.dataset.userAvatar || '';
    var aiAvatarHtml = container.dataset.aiAvatar || '';

    var pendingInitialdata = null;
    var sending = false;

    function addMessage(role, content) {
        var wrapper = document.createElement('div');
        wrapper.className = 'd-flex mb-2 align-items-start gap-2' + (role === 'user' ? ' flex-row-reverse' : '');

        // Avatar
        var avatarDiv = document.createElement('div');
        avatarDiv.className = 'flex-shrink-0';
        avatarDiv.innerHTML = role === 'user' ? userAvatarHtml : aiAvatarHtml;
        wrapper.appendChild(avatarDiv);

        // Message bubble
        var bubble = document.createElement('div');
        bubble.className = 'ai-chat-message-content rounded-3 py-2 px-3';

        if (role === 'user') {
            bubble.classList.add('bg-primary', 'text-white');
        } else {
            bubble.classList.add('bg-body-secondary', 'border');
        }

        // Basic formatting
        bubble.innerHTML = formatMessage(escapeHtml(content));
        wrapper.appendChild(bubble);
        messagesDiv.appendChild(wrapper);
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
    }

    function addThinking() {
        var wrapper = document.createElement('div');
        wrapper.className = 'd-flex mb-2 align-items-start gap-2';
        wrapper.id = 'ai-chat-thinking';

        var avatarDiv = document.createElement('div');
        avatarDiv.className = 'flex-shrink-0';
        avatarDiv.innerHTML = aiAvatarHtml;
        wrapper.appendChild(avatarDiv);

        var bubble = document.createElement('div');
        bubble.className = 'ai-chat-message-content bg-body-secondary border rounded-3 py-2 px-3 text-secondary fst-italic';
        bubble.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status"></span>Thinking...';

        wrapper.appendChild(bubble);
        messagesDiv.appendChild(wrapper);
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
    }

    function removeThinking() {
        var el = document.getElementById('ai-chat-thinking');
        if (el) el.remove();
    }

    function escapeHtml(text) {
        var div = document.createElement('div');
        div.appendChild(document.createTextNode(text));
        return div.innerHTML;
    }

    function formatMessage(html) {
        html = html.replace(/```json-initialdata\n([\s\S]*?)```/g, '<pre class="bg-body-secondary border rounded p-2 my-2 small overflow-auto"><code>$1</code></pre>');
        html = html.replace(/```(\w*)\n([\s\S]*?)```/g, '<pre class="bg-body-secondary border rounded p-2 my-2 small overflow-auto"><code>$2</code></pre>');
        html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
        html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\n/g, '<br>');
        return html;
    }

    function sendMessage() {
        var message = input.value.trim();
        if (!message || sending) return;

        sending = true;
        sendBtn.disabled = true;
        input.disabled = true;

        // Dismiss review panel if visible
        if (applySection.style.display !== 'none') {
            applySection.style.transition = 'opacity 0.3s';
            applySection.style.opacity = '0';
            setTimeout(function() {
                applySection.style.display = 'none';
                applySection.style.opacity = '';
                applySection.style.transition = '';
            }, 300);
            pendingInitialdata = null;
        }

        addMessage('user', message);
        input.value = '';
        addThinking();

        fetch(RT.Config.WebPath + '/Helpers/AIChat/SendMessage', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'message=' + encodeURIComponent(message) + '&session_id=' + encodeURIComponent(sessionId)
        })
        .then(function(response) { return response.json(); })
        .then(function(data) {
            removeThinking();

            if (data.success) {
                var displayText = data.response;
                if (data.has_initialdata && data.initialdata) {
                    // Strip the JSON block from the chat display since
                    // it will be shown in the Review Configuration panel
                    displayText = displayText.replace(/```json-initialdata\s*\n[\s\S]*?\n```/g, '');
                    displayText = displayText.replace(/```json?\s*\n\{[\s\S]*?\}\s*\n```/g, '');
                    displayText = displayText.trim();
                    pendingInitialdata = data.initialdata;
                    showApplySection(data.initialdata);
                }
                addMessage('assistant', displayText);
            } else {
                addMessage('assistant', 'Error: ' + (data.error || 'Unknown error'));
            }
        })
        .catch(function(err) {
            removeThinking();
            addMessage('assistant', 'Error: Could not reach the AI service. ' + err.message);
        })
        .finally(function() {
            sending = false;
            sendBtn.disabled = false;
            input.disabled = false;
            input.focus();
        });
    }

    function showApplySection(initialdata) {
        previewDiv.innerHTML = buildSummary(initialdata);
        rawJsonContent.textContent = JSON.stringify(initialdata, null, 2);
        applySection.style.display = '';
        resultsDiv.style.display = 'none';
        resultsDiv.innerHTML = '';
        applyBtn.style.display = '';
        applyBtn.disabled = false;
    }

    var cfTypeLabels = {
        'SelectSingle': 'Dropdown',
        'SelectMultiple': 'Multi-select dropdown',
        'FreeformSingle': 'Text',
        'FreeformMultiple': 'Multi-value text',
        'Text': 'Text area',
        'HTML': 'Rich text',
        'Wikitext': 'Wiki text',
        'BinarySingle': 'File upload',
        'BinaryMultiple': 'Multiple file upload',
        'ImageSingle': 'Image upload',
        'ImageMultiple': 'Multiple image upload',
        'Combobox': 'Combobox',
        'AutocompleteSingle': 'Autocomplete',
        'AutocompleteMultiple': 'Multi-value autocomplete',
        'Date': 'Date',
        'DateTime': 'Date and time',
        'IPAddressSingle': 'IP address',
        'IPAddressMultiple': 'Multiple IP addresses',
        'IPAddressRangeSingle': 'IP range',
        'IPAddressRangeMultiple': 'Multiple IP ranges'
    };

    function friendlyCfType(type) {
        return cfTypeLabels[type] || type;
    }

    function buildSummary(data) {
        var html = '<dl class="row mb-0">';

        if (data.Lifecycle) {
            html += '<dt class="col-sm-3">Lifecycle</dt>';
            html += '<dd class="col-sm-9"><strong>' + escapeHtml(data.Lifecycle.name) + '</strong>';
            var statuses = data.Lifecycle.statuses || {};
            var allStatuses = [].concat(
                statuses.initial || [],
                statuses.active || [],
                statuses.inactive || []
            );
            html += ' &mdash; ' + allStatuses.map(escapeHtml).join(', ');
            html += '</dd>';
        }

        if (data.Queues) {
            data.Queues.forEach(function(q) {
                html += '<dt class="col-sm-3">Queue</dt>';
                html += '<dd class="col-sm-9"><strong>' + escapeHtml(q.Name) + '</strong>';
                if (q.Description) html += ' &mdash; ' + escapeHtml(q.Description);
                html += '</dd>';
            });
        }

        if (data.Groups) {
            html += '<dt class="col-sm-3">Groups</dt>';
            html += '<dd class="col-sm-9">' + data.Groups.map(function(g) {
                return escapeHtml(g.Name);
            }).join(', ') + '</dd>';
        }

        if (data.CustomFields) {
            html += '<dt class="col-sm-3">Custom Fields</dt>';
            html += '<dd class="col-sm-9">' + data.CustomFields.map(function(cf) {
                return escapeHtml(cf.Name) + ' (' + friendlyCfType(cf.Type) + ')';
            }).join(', ') + '</dd>';
        }

        if (data.ACL) {
            var principals = [];
            var seen = {};
            data.ACL.forEach(function(acl) {
                var name = acl.GroupId || acl.GroupType || '';
                if (name && !seen[name]) {
                    seen[name] = true;
                    principals.push(name);
                }
            });
            html += '<dt class="col-sm-3">Rights Granted To</dt>';
            html += '<dd class="col-sm-9">' + principals.map(escapeHtml).join(', ') + '</dd>';
        }

        if (data.Watchers) {
            var watcherList = [];
            if (data.Watchers.AdminCc) {
                data.Watchers.AdminCc.forEach(function(w) {
                    watcherList.push(escapeHtml(w) + ' (AdminCc)');
                });
            }
            if (data.Watchers.Cc) {
                data.Watchers.Cc.forEach(function(w) {
                    watcherList.push(escapeHtml(w) + ' (Cc)');
                });
            }
            if (watcherList.length) {
                html += '<dt class="col-sm-3">Queue Watchers</dt>';
                html += '<dd class="col-sm-9">' + watcherList.join(', ') + '</dd>';
            }
        }

        html += '</dl>';
        return html;
    }

    function applyConfiguration() {
        if (!pendingInitialdata) return;

        applyBtn.disabled = true;
        resultsDiv.style.display = '';
        resultsDiv.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status"></span>Creating queue...';

        fetch(RT.Config.WebPath + '/Helpers/AIChat/ApplyInitialdata', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'initialdata_json=' + encodeURIComponent(JSON.stringify(pendingInitialdata)) + '&session_id=' + encodeURIComponent(sessionId)
        })
        .then(function(response) { return response.json(); })
        .then(function(data) {
            if (data.success) {
                var html = '<div class="alert alert-success">';
                html += '<strong>Configuration applied successfully!</strong>';
                if (data.queue_url) {
                    html += '<br><a href="' + data.queue_url + '">View the new queue</a>';
                }
                if (data.messages && data.messages.length) {
                    html += '<ul class="mb-0 mt-2">';
                    data.messages.forEach(function(msg) {
                        html += '<li>' + escapeHtml(msg) + '</li>';
                    });
                    html += '</ul>';
                }
                html += '</div>';
                resultsDiv.innerHTML = html;
                pendingInitialdata = null;
                applyBtn.style.display = 'none';
            } else {
                resultsDiv.innerHTML = '<div class="alert alert-danger">'
                    + '<strong>Error:</strong> ' + escapeHtml(data.error || 'Unknown error')
                    + '</div>';
                applyBtn.disabled = false;
            }
        })
        .catch(function(err) {
            resultsDiv.innerHTML = '<div class="alert alert-danger">'
                + '<strong>Error:</strong> ' + escapeHtml(err.message)
                + '</div>';
            applyBtn.disabled = false;
        })
        .finally(function() {});
    }

    // Event listeners
    sendBtn.addEventListener('click', sendMessage);

    input.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    applyBtn.addEventListener('click', applyConfiguration);

    // On page load, apply formatting to server-rendered assistant messages
    // and check for initialdata JSON in the last message
    var existingMsgs = messagesDiv.querySelectorAll('.ai-chat-message-content');
    if (existingMsgs.length > 1) {
        for (var i = 0; i < existingMsgs.length; i++) {
            var msg = existingMsgs[i];
            // Only format assistant messages (bg-body-secondary), skip user messages (bg-primary)
            if (msg.classList.contains('bg-body-secondary')) {
                msg.innerHTML = formatMessage(escapeHtml(msg.textContent));
            }
        }

        var lastMsg = existingMsgs[existingMsgs.length - 1];
        var text = lastMsg.textContent || '';
        var jsonMatch = text.match(/\{[\s\S]*"(?:Queues|Groups|ACL)"[\s\S]*\}/);
        if (jsonMatch) {
            try {
                // Strip comments and trailing commas like SendMessage does
                var cleaned = jsonMatch[0].replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/,\s*([\]\}])/g, '$1');
                var parsed = JSON.parse(cleaned);
                if (parsed.Queues || parsed.ACL || parsed.Groups) {
                    pendingInitialdata = parsed;
                    showApplySection(parsed);
                    // Strip the JSON from the displayed message
                    lastMsg.innerHTML = lastMsg.innerHTML.replace(/<pre[\s\S]*?<\/pre>/g, '').trim();
                }
            } catch(e) { /* not valid JSON, ignore */ }
        }
    }

    input.focus();
}

if (typeof htmx !== 'undefined') {
    htmx.onLoad(initAIChat);
} else {
    document.addEventListener('DOMContentLoaded', initAIChat);
}
