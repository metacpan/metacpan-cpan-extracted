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

    rootElement.querySelectorAll('[reactive\\:model]').forEach(el => {
        let property = el.getAttribute('reactive:model')

        el.value = data[property]
    })

    rootElement.querySelectorAll('[reactive\\:model\\.lazy]').forEach(el => {
        let property = el.getAttribute('reactive:model.lazy')

        el.value = data[property]
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
        if (! e.target.hasAttribute('reactive:model')) return;

        let property = e.target.getAttribute('reactive:model');
        let value = e.target.value;

        sendRequest(rootElement, {
            updateProperty: [property, value],
        });
    })
}

function initReactiveModelLazy(rootElement) {
    let data = rootElement.__reactive.data;

    updateReactiveModelInputs(rootElement)

    rootElement.addEventListener('change', e => {
        if (! e.target.hasAttribute('reactive:model.lazy')) return;

        let property = e.target.getAttribute('reactive:model.lazy');
        let value = e.target.value;

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
