export async function fetchAiResults(inputText, optionType) {
    try {
        const response = await fetch('/Helpers/AISuggestion/ProcessAIRequest', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ rawText: inputText, callType: optionType, id: getTicketIdFromUrl(window.location.href) }).toString()
        });

        if (!response.ok) {
            console.error('Error in fetchAiResults:', response.status, response.statusText);
            return 'No suggestion available.';
        }

        const suggestion = await response.text();

        if (!suggestion) {
            console.warn('No suggestion found in response:', suggestion);
            return 'No suggestion available.';
        }

        return suggestion;
    } catch (error) {
        console.error('Error fetching AI results:', error);
        return 'No suggestion available.';
    }
}

export function resetSelectionToSafePosition(editor, writer) {
    const root = editor.model.document.getRoot();
    const position = writer.createPositionAt(root, 'end');
    writer.setSelection(position);
}

export function getEditorSelectionOrContent(editor) {
    let selectedText = '';
    let isSelectedText = false;

    const selection = editor.model.document.selection;

    if (!selection.isCollapsed) {
        const range = selection.getFirstRange();
        if (range) {
            for (const item of range.getItems()) {
                if (item.is('$textProxy')) {
                    selectedText += item.data;
                }
            }
            isSelectedText = true;
        }
    }

    return {
        content: isSelectedText ? selectedText : editor.data.get(),
        isSelected: isSelectedText
    };
}

export function stripHTML(html) {
    const doc = new DOMParser().parseFromString(html, 'text/html');
    return doc.body.textContent || '';
}

export function extractParagraphsFromHTML(input) {
    const isHTML = /<\/?[a-z][\s\S]*>/i.test(input);

    if (!isHTML) {
        return input.trim();
    }

    const parser = new DOMParser();
    const doc = parser.parseFromString(input, 'text/html');
    const paragraphs = Array.from(doc.querySelectorAll('p')).map((p) => p.textContent?.trim() || '');
    return paragraphs.filter(Boolean).join('\n');
}

export function getTicketIdFromUrl(url) {
    try {
        const urlObject = new URL(url);

        // We only want ids for tickets
        if (urlObject.pathname.includes("Ticket")) {

            // The URLSearchParams API expects '&' as a separator.
            // Replace all semicolons with ampersands to ensure correct parsing.
            // We use slice(1) to remove the leading '?' before replacing.
            let queryString = urlObject.search;
            queryString = queryString.slice(1).replace(/;/g, '&');

            const params = new URLSearchParams(queryString);

            if (params.has("id")) {
                const ticketId = parseInt(params.get("id"), 10);

                if (!isNaN(ticketId)) {
                    return ticketId;
                } else {
                    console.error("The 'id' parameter is not a valid number.");
                    return null;
                }
            }
        }
    } catch (error) {
        console.error("Error parsing the URL:", error);
        return null;
    }
    return null;
}

export function isAIEditorPage() {
    const currentUrl = window.location.href;

    const showAIFeatures = window.RT_AI_ActiveForCurrentQueue;

    // Todo: Make this configuration
    const isEditorPage = currentUrl.includes("Ticket/Update.html") || currentUrl.includes("Ticket/Create.html");

    if (showAIFeatures && isEditorPage) {
        return 1;
    } else {
        return 0;
    }
}
