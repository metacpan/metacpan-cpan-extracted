document.querySelectorAll('[reactive\\:snapshot]').forEach(el => {
    el.__reactive = JSON.parse(el.getAttribute('reactive:snapshot'));
    el.removeAttribute('reactive:snapshot')

    initReactiveClick(el);
    initReactiveClickIncrement(el);
    initReactiveClickDecrement(el);
    initReactiveClickUnset(el);
    initReactiveModel(el);
    initReactiveModelLazy(el);
});

function sendRequest(el, addToPayload) {
    let snapshot = el.__reactive;

    fetch('/reactive', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: JSON.stringify({
            snapshot,
            ...addToPayload,
        }),
    })
    .then(response => response.json())
    .then(response => {
        let {html, snapshot} = response;

        el.__reactive = snapshot;

        Alpine.morph(el, html)

        updateReactiveModelInputs(el)
    });
}

function updateReactiveModelInputs(rootElement) {
    let data = rootElement.__reactive.data;

    const regex = /^([A-Z]*)(?:\[(\d+)\])?(?:\.([A-Z]+))?$/i;

    const handleValue = (el, attr) => {
        let property = el.getAttribute(attr)
        let match = property.match(regex)

        let value;

        if (match && typeof match[3] !== 'undefined') {
            value = data[match[1]][match[2]][match[3]]
        } else if (match && typeof match[2] !== 'undefined') {
            value = data[match[1]][match[2]]
        } else {
            value = data[property]
        }

        if (el.type === 'checkbox') {
            el.checked = !! value
        } else if (el.type === 'radio') {
            el.checked = (el.value == value)
        } else {
            el.value = value
        }

    }

    rootElement.querySelectorAll('[reactive\\:model]').forEach(el => {
        handleValue(el, 'reactive:model')
    })

    rootElement.querySelectorAll('[reactive\\:model\\.lazy]').forEach(el => {
        handleValue(el, 'reactive:model.lazy')
    })
}

function initReactiveClick(rootElement) {
    rootElement.addEventListener('click', e => {
        const attr = 'reactive:click'
        const el = findElWithAttributeBetween(rootElement, e.target, attr)
        if (el === null) return;

        let method = el.getAttribute(attr);

        sendRequest(rootElement, {callMethod: method});
    })
}

function initReactiveModel(rootElement) {
    let data = rootElement.__reactive.data;

    updateReactiveModelInputs(rootElement)

    rootElement.addEventListener('input', e => {
        let el = e.target;

        if (! el.hasAttribute('reactive:model')) return;

        let property = el.getAttribute('reactive:model');
        let value = el.value;

        if (el.type === 'checkbox' && !el.checked) {
            value = 0;
        }

        sendRequest(rootElement, {
            updateProperty: [property, value],
        });
    })
}

function initReactiveModelLazy(rootElement) {
    let data = rootElement.__reactive.data;

    updateReactiveModelInputs(rootElement)

    rootElement.addEventListener('change', e => {
        let el = e.target;

        if (! el.hasAttribute('reactive:model.lazy')) return;

        let property = el.getAttribute('reactive:model.lazy');
        let value = el.value;

        if (el.type === 'checkbox' && !el.checked) {
            value = 0;
        }

        sendRequest(rootElement, {
            updateProperty: [property, value],
        });
    })
}

function initReactiveClickIncrement(rootElement) {
    initReactiveClickCommon(rootElement, 'increment');
}

function initReactiveClickDecrement(rootElement) {
    initReactiveClickCommon(rootElement, 'decrement');
}

function initReactiveClickUnset(rootElement) {
    initReactiveClickCommon(rootElement, 'unset');
}

function initReactiveClickCommon(rootElement, action) {
    rootElement.addEventListener('click', e => {
        const attr = `reactive:click.${action}`
        const el = findElWithAttributeBetween(rootElement, e.target, attr)
        if (el === null) return;

        let value = el.getAttribute(attr);

        let data = {};
        data[action] = value;

        sendRequest(rootElement, data);
    })
}

function findElWithAttributeBetween(rootElement, element, attribute) {
    if (element.hasAttribute(attribute))
        return element;

    if (element === rootElement)
        return null;

    return findElWithAttributeBetween(rootElement, element.parentElement, attribute);
}
